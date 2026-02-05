const { requireAuth, optionalAuth } = require('../middleware/auth');
const { pool } = require('../db');
const { evaluateArenaAchievements } = require('../services/arena_achievements');

// 服务器对战房间（内存存储，重启清空）：roomId -> { hostPhone, hostName, guestPhone?, guestName?, topic, subtopic, seed, count, hostResult?, guestResult?, createdAt }
const duelRooms = new Map();
const DUEL_ROOM_TTL_MS = 30 * 60 * 1000; // 30 分钟无活动可清理

// 匹配队列：{ phone, name, topic, subtopic, createdAt }；先进入的优先被匹配
let duelMatchQueue = [];
// 已匹配但尚未轮询到的用户：phone -> { roomId, topic, subtopic, seed, count, opponentName, isHost }
const duelPendingMatch = new Map();
const MATCH_QUEUE_TTL_MS = 60 * 1000; // 队列中超过 60 秒未匹配则视为过期

function randomRoomId() {
  let id = '';
  for (let i = 0; i < 6; i++) id += Math.floor(Math.random() * 10);
  return id;
}

function cleanMatchQueue() {
  const now = Date.now();
  duelMatchQueue = duelMatchQueue.filter((e) => now - e.createdAt < MATCH_QUEUE_TTL_MS);
}

function routes(app) {
  // 题库主题与子主题（供前端筛选器、分区榜使用）
  app.get('/arena/topics', async (_req, res) => {
    try {
      const r = await pool.query(
        'SELECT DISTINCT topic, subtopic FROM arena_questions ORDER BY topic, subtopic'
      );
      const byTopic = {};
      for (const row of r.rows || []) {
        const t = row.topic || '全部';
        if (!byTopic[t]) byTopic[t] = [];
        const sub = row.subtopic || '综合知识';
        if (!byTopic[t].includes(sub)) byTopic[t].push(sub);
      }
      const topics = Object.entries(byTopic).map(([topic, subtopics]) => ({
        topic,
        subtopics: ['全部', ...subtopics],
      }));
      res.json({ topics });
    } catch (err) {
      console.error('[arena topics]', err);
      res.status(500).json({ error: 'server_error', message: '获取主题列表失败' });
    }
  });

  // 题库列表（可不登录访问）；?topic=历史&subtopic=朝代故事 按主题/子主题筛选
  app.get('/arena/questions', async (req, res) => {
    const topic = req.query.topic && String(req.query.topic).trim();
    const subtopic = req.query.subtopic && String(req.query.subtopic).trim();
    try {
      let r;
      if (topic && topic !== '全部') {
        if (subtopic && subtopic !== '全部') {
          r = await pool.query(
            'SELECT id, topic, subtopic, title, options, answer FROM arena_questions WHERE topic = $1 AND subtopic = $2 ORDER BY id',
            [topic, subtopic]
          );
        } else {
          r = await pool.query(
            'SELECT id, topic, subtopic, title, options, answer FROM arena_questions WHERE topic = $1 ORDER BY id',
            [topic]
          );
        }
      } else {
        r = await pool.query(
          'SELECT id, topic, subtopic, title, options, answer FROM arena_questions ORDER BY id'
        );
      }
      const list = (r.rows || []).map((row) => ({
        id: row.id,
        topic: row.topic || '全部',
        subtopic: row.subtopic || '综合知识',
        title: row.title,
        options: Array.isArray(row.options) ? row.options : (row.options && row.options.length != null ? Array.from(row.options) : []),
        answer: row.answer || 'A',
      }));
      res.json({ questions: list });
    } catch (err) {
      console.error('[arena questions]', err);
      res.status(500).json({ error: 'server_error', message: '获取题库失败' });
    }
  });

  app.get('/arena/stats', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    try {
      const r = await pool.query(
        'SELECT matches, max_streak, total_score, pk_score, best_accuracy, topic_best FROM user_arena_stats WHERE phone = $1',
        [phone]
      );
      if (!r.rows.length) {
        return res.json({
          matches: 0,
          maxStreak: 0,
          totalScore: 0,
          pkScore: 0,
          bestAccuracy: 0,
          topicBest: {},
        });
      }
      const row = r.rows[0];
      const topicBest = row.topic_best && typeof row.topic_best === 'object'
        ? row.topic_best
        : {};
      res.json({
        matches: row.matches ?? 0,
        maxStreak: row.max_streak ?? 0,
        totalScore: row.total_score ?? 0,
        pkScore: row.pk_score ?? 0,
        bestAccuracy: Number(row.best_accuracy) ?? 0,
        topicBest,
      });
    } catch (err) {
      console.error('[arena stats]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });

  // 在线 PK 排行（type=pk，按 pk_score）/ 个人积分排行（type=personal 或不传，按 total_score）
  // ?type=pk | ?type=personal；?limit=5 首页前5，?limit=200 详情全量；?search= 按昵称搜索
  app.get('/arena/leaderboard/score', optionalAuth, async (req, res) => {
    const limit = Math.min(parseInt(req.query.limit, 10) || 10, 200);
    const search = (req.query.search && String(req.query.search).trim()) || '';
    const type = (req.query.type && String(req.query.type).trim()) || 'personal';
    const orderByPk = type === 'pk';
    const scoreCol = orderByPk ? 's.pk_score' : 's.total_score';
    const authPhone = req.auth?.phone;
    try {
      const r = await pool.query(
        `WITH ranked AS (
           SELECT u.phone, u.name, ${scoreCol} AS score,
                  ROW_NUMBER() OVER (ORDER BY ${scoreCol} DESC NULLS LAST) AS rn
           FROM user_arena_stats s
           JOIN users u ON u.phone = s.phone
         )
         SELECT phone, name, score, rn FROM ranked
         WHERE ($2::text = '' OR name ILIKE '%' || $2 || '%')
         ORDER BY rn
         LIMIT $1`,
        [search ? 200 : limit, search]
      );
      const list = (r.rows || []).map((row) => ({
        rank: Number(row.rn) || 0,
        name: row.name || '',
        score: Number(row.score) || 0,
        isMe: !!authPhone && row.phone === authPhone,
      }));
      res.json({ list });
    } catch (err) {
      console.error('[arena leaderboard/score]', err);
      res.status(500).json({ error: 'server_error', message: '获取排行榜失败' });
    }
  });

  // 局域网 PK 结束后提交得分，只更新 pk_score（在线 PK 排行用）
  app.post('/arena/pk/submit', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const score = req.body && req.body.score != null ? Number(req.body.score) : 0;
    if (score < 0) {
      return res.status(400).json({ error: 'invalid_data', message: '无效得分' });
    }
    try {
      await pool.query(
        `INSERT INTO user_arena_stats (phone, pk_score, updated_at)
         VALUES ($1, $2, extract(epoch from now())::bigint)
         ON CONFLICT (phone) DO UPDATE SET
           pk_score = user_arena_stats.pk_score + $2,
           updated_at = extract(epoch from now())::bigint`,
        [phone, score]
      );
      res.json({ message: '提交成功' });
    } catch (err) {
      console.error('[arena pk/submit]', err);
      res.status(500).json({ error: 'server_error', message: '提交失败' });
    }
  });

  // 局域网对战记录：提交本场对战（我方得分、对手手机号、对手得分），用于最近挑战与胜负判定
  app.post('/arena/duel/submit', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const { opponentPhone, myScore, opponentScore } = req.body || {};
    const opp = opponentPhone != null ? String(opponentPhone).trim() : '';
    const my = Number(myScore);
    const oppScore = Number(opponentScore);
    if (opp === '') {
      return res.status(400).json({ error: 'invalid_data', message: '需要对手手机号' });
    }
    try {
      await pool.query(
        `INSERT INTO arena_lan_duel_sessions (user_phone, opponent_phone, user_score, opponent_score)
         VALUES ($1, $2, $3, $4)`,
        [phone, opp, my, oppScore]
      );
      res.json({ message: '提交成功' });
    } catch (err) {
      console.error('[arena duel/submit]', err);
      res.status(500).json({ error: 'server_error', message: '提交失败' });
    }
  });

  // ---------- 服务器对战（匹配 / 房间） ----------
  // 开始匹配：两人差不多时间点「开始对战」即自动配对
  app.post('/arena/duel/match', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const name = (req.auth && req.auth.name) ? String(req.auth.name) : '星知玩家';
    const topic = (req.body && req.body.topic) ? String(req.body.topic).trim() : '全部';
    const subtopic = (req.body && req.body.subtopic) ? String(req.body.subtopic).trim() : '全部';
    cleanMatchQueue();
    let other = null;
    const idx = duelMatchQueue.findIndex((e) => e.phone !== phone);
    if (idx >= 0) {
      other = duelMatchQueue[idx];
      duelMatchQueue.splice(idx, 1);
    }
    if (other) {
      const seed = Math.abs((phone + other.phone + Date.now()).split('').reduce((a, c) => a + c.charCodeAt(0), 0)) % 1000000;
      const count = 10;
      let roomId = randomRoomId();
      while (duelRooms.has(roomId)) roomId = randomRoomId();
      duelRooms.set(roomId, {
        hostPhone: other.phone,
        hostName: other.name,
        guestPhone: phone,
        guestName: name,
        topic: other.topic,
        subtopic: other.subtopic,
        seed,
        count,
        hostResult: null,
        guestResult: null,
        createdAt: Date.now(),
      });
      duelPendingMatch.set(other.phone, {
        roomId,
        topic: other.topic,
        subtopic: other.subtopic,
        seed,
        count,
        opponentName: name,
        isHost: true,
      });
      return res.json({
        matched: true,
        roomId,
        topic: other.topic,
        subtopic: other.subtopic,
        seed,
        count,
        opponentName: other.name,
        isHost: false,
      });
    }
    duelMatchQueue.push({ phone, name, topic, subtopic, createdAt: Date.now() });
    return res.json({ matched: false, waiting: true });
  });

  // 轮询是否已匹配（等待中的用户调用）
  app.get('/arena/duel/match', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const pending = duelPendingMatch.get(phone);
    if (pending) {
      duelPendingMatch.delete(phone);
      return res.json({ matched: true, ...pending });
    }
    return res.json({ matched: false });
  });

  // 创建对战房间，返回房间号（保留，可选使用）
  app.post('/arena/duel/room', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const name = (req.auth && req.auth.name) ? String(req.auth.name) : '房主';
    const topic = (req.body && req.body.topic) ? String(req.body.topic).trim() : '全部';
    const subtopic = (req.body && req.body.subtopic) ? String(req.body.subtopic).trim() : '全部';
    const seed = Math.abs((phone + Date.now()).split('').reduce((a, c) => a + c.charCodeAt(0), 0)) % 1000000;
    const count = 10;
    let roomId = randomRoomId();
    while (duelRooms.has(roomId)) roomId = randomRoomId();
    duelRooms.set(roomId, {
      hostPhone: phone,
      hostName: name,
      guestPhone: null,
      guestName: null,
      topic,
      subtopic,
      seed,
      count,
      hostResult: null,
      guestResult: null,
      createdAt: Date.now(),
    });
    return res.json({ roomId, topic, subtopic, seed, count });
  });

  // 加入对战房间
  app.post('/arena/duel/room/:roomId/join', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const name = (req.auth && req.auth.name) ? String(req.auth.name) : '对手';
    const roomId = String(req.params.roomId || '').trim();
    const room = duelRooms.get(roomId);
    if (!room) return res.status(404).json({ error: 'not_found', message: '房间不存在或已关闭' });
    if (room.guestPhone) return res.status(400).json({ error: 'room_full', message: '房间已满' });
    if (room.hostPhone === phone) return res.status(400).json({ error: 'same_user', message: '不能加入自己创建的房间' });
    room.guestPhone = phone;
    room.guestName = name;
    return res.json({
      topic: room.topic,
      subtopic: room.subtopic,
      seed: room.seed,
      count: room.count,
      hostName: room.hostName,
    });
  });

  // 查询房间状态（用于轮询对手结果）
  app.get('/arena/duel/room/:roomId', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const roomId = String(req.params.roomId || '').trim();
    const room = duelRooms.get(roomId);
    if (!room) return res.status(404).json({ error: 'not_found', message: '房间不存在或已关闭' });
    const isHost = room.hostPhone === phone;
    const isGuest = room.guestPhone === phone;
    if (!isHost && !isGuest) return res.status(403).json({ error: 'forbidden', message: '你不是该房间成员' });
    const myResult = isHost ? room.hostResult : room.guestResult;
    const oppResult = isHost ? room.guestResult : room.hostResult;
    const oppName = isHost ? room.guestName : room.hostName;
    const payload = {
      topic: room.topic,
      subtopic: room.subtopic,
      seed: room.seed,
      count: room.count,
      myResult: myResult ? { score: myResult.score, correctCount: myResult.correctCount, total: myResult.total } : null,
    };
    if (oppResult) {
      payload.opponentScore = oppResult.score;
      payload.opponentCorrect = oppResult.correctCount;
      payload.opponentTotal = oppResult.total;
      payload.opponentName = oppName || '对手';
      duelRooms.delete(roomId);
    }
    return res.json(payload);
  });

  // 提交本局结果；若双方都已提交则返回对手结果并写入对战记录（房间保留供先提交者轮询，在其 GET 到结果后再删）
  app.post('/arena/duel/room/:roomId/submit', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const roomId = String(req.params.roomId || '').trim();
    const { score, correctCount, total } = req.body || {};
    const room = duelRooms.get(roomId);
    if (!room) return res.status(404).json({ error: 'not_found', message: '房间不存在或已关闭' });
    const isHost = room.hostPhone === phone;
    const isGuest = room.guestPhone === phone;
    if (!isHost && !isGuest) return res.status(403).json({ error: 'forbidden', message: '你不是该房间成员' });
    const s = Number(score) || 0;
    const c = Number(correctCount) || 0;
    const t = Number(total) || 0;
    if (isHost) room.hostResult = { score: s, correctCount: c, total: t };
    else room.guestResult = { score: s, correctCount: c, total: t };
    const oppResult = isHost ? room.guestResult : room.hostResult;
    const oppName = isHost ? room.guestName : room.hostName;
    const oppPhone = isHost ? room.guestPhone : room.hostPhone;
    if (oppResult) {
      try {
        await pool.query(
          `INSERT INTO arena_lan_duel_sessions (user_phone, opponent_phone, user_score, opponent_score)
           VALUES ($1, $2, $3, $4), ($2, $1, $4, $3)`,
          [phone, oppPhone || '', s, oppResult.score]
        );
      } catch (e) {
        console.error('[arena duel room submit insert]', e);
      }
    }
    const response = {
      ok: true,
      opponentScore: oppResult ? oppResult.score : null,
      opponentCorrect: oppResult ? oppResult.correctCount : null,
      opponentTotal: oppResult ? oppResult.total : null,
      opponentName: oppName || '对手',
      opponentPhone: oppPhone || '',
    };
    return res.json(response);
  });

  // 局域网对战记录列表（最近挑战用）
  app.get('/arena/duel/history', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
    try {
      const r = await pool.query(
        `SELECT d.id, d.opponent_phone, d.user_score, d.opponent_score, d.created_at,
                u.name AS opponent_name
         FROM arena_lan_duel_sessions d
         LEFT JOIN users u ON u.phone = d.opponent_phone
         WHERE d.user_phone = $1
         ORDER BY d.created_at DESC
         LIMIT $2`,
        [phone, limit]
      );
      const list = (r.rows || []).map((row) => {
        const mySc = Number(row.user_score) ?? 0;
        const oppSc = Number(row.opponent_score) ?? 0;
        return {
          id: row.id,
          opponentPhone: row.opponent_phone ?? '',
          opponentName: row.opponent_name ?? '对手',
          myScore: mySc,
          opponentScore: oppSc,
          result: mySc > oppSc ? 'win' : 'lose',
          createdAt: row.created_at,
        };
      });
      res.json({ list });
    } catch (err) {
      console.error('[arena duel/history]', err);
      res.status(500).json({ error: 'server_error', message: '获取对战记录失败' });
    }
  });

  // 单人挑战：做完所有题目后提交，才记录得分并写入挑战记录
  app.post('/arena/challenge/submit', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const { topic, subtopic, totalQuestions, correctCount, score, answers, maxStreak } = req.body || {};
    const total = totalQuestions != null ? Number(totalQuestions) : 0;
    const correct = correctCount != null ? Number(correctCount) : 0;
    const finalScore = score != null ? Number(score) : 0;
    const t = (topic && String(topic).trim()) || '全部';
    const st = (subtopic && String(subtopic).trim()) || '全部';
    const ans = Array.isArray(answers) ? answers : [];
    const maxS = maxStreak != null ? Number(maxStreak) : 0;
    if (total < 1 || ans.length !== total) {
      return res.status(400).json({ error: 'invalid_data', message: '请完成全部题目后再提交' });
    }
    try {
      const r = await pool.query(
        `INSERT INTO arena_challenge_sessions (phone, topic, subtopic, total_questions, correct_count, score, answers)
         VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb)
         RETURNING id, created_at`,
        [phone, t, st, total, correct, finalScore, JSON.stringify(ans)]
      );
      const accuracy = total > 0 ? correct / total : 0;
      const topicBestKey = t !== '全部' ? t : null;
      await pool.query(
        `INSERT INTO user_arena_stats (phone, matches, max_streak, total_score, best_accuracy, topic_best, updated_at)
         VALUES ($1, 1, $2, $3, $4, $5::jsonb, extract(epoch from now())::bigint)
         ON CONFLICT (phone) DO UPDATE SET
           matches = user_arena_stats.matches + 1,
           max_streak = GREATEST(user_arena_stats.max_streak, $2),
           total_score = user_arena_stats.total_score + $3,
           best_accuracy = GREATEST(user_arena_stats.best_accuracy, $4),
           topic_best = CASE WHEN ($6::text) IS NOT NULL AND ($6::text) <> '' THEN
             jsonb_set(
               COALESCE(user_arena_stats.topic_best, '{}'::jsonb),
               ARRAY[$6::text],
               to_jsonb(GREATEST(COALESCE((user_arena_stats.topic_best->>($6::text))::int, 0), $3)::int)
             ) ELSE user_arena_stats.topic_best END,
           updated_at = extract(epoch from now())::bigint`,
        [phone, maxS, finalScore, accuracy, topicBestKey ? JSON.stringify({ [topicBestKey]: finalScore }) : '{}', topicBestKey]
      );
      const row = r.rows[0];
      const sessionPayload = {
        topic: t,
        subtopic: st,
        totalQuestions: total,
        correctCount: correct,
        score: finalScore,
        maxStreak: maxS,
      };

      // 查询更新后的统计、累计答对数、各分区挑战次数、已解锁成就
      const [statsRes, unlockedRes, sumRes, topicCountRes] = await Promise.all([
        pool.query(
          'SELECT matches, max_streak, total_score, best_accuracy, topic_best FROM user_arena_stats WHERE phone = $1',
          [phone]
        ),
        pool.query(
          'SELECT achievement_id FROM user_achievements WHERE phone = $1',
          [phone]
        ),
        pool.query(
          'SELECT COALESCE(SUM(correct_count), 0) AS total_correct FROM arena_challenge_sessions WHERE phone = $1',
          [phone]
        ),
        pool.query(
          'SELECT topic, COUNT(*) AS cnt FROM arena_challenge_sessions WHERE phone = $1 GROUP BY topic',
          [phone]
        ),
      ]);

      const statsRow = statsRes.rows[0];
      const stats = statsRow ? {
        matches: statsRow.matches ?? 0,
        max_streak: statsRow.max_streak ?? 0,
        total_score: statsRow.total_score ?? 0,
        best_accuracy: statsRow.best_accuracy ?? 0,
        topic_best: statsRow.topic_best && typeof statsRow.topic_best === 'object' ? statsRow.topic_best : {},
      } : {};
      const unlockedIds = new Set((unlockedRes.rows || []).map((r) => r.achievement_id));
      const totalCorrect = Number(sumRes.rows[0]?.total_correct) || 0;
      const topicSessionCounts = {};
      for (const r of topicCountRes.rows || []) {
        topicSessionCounts[r.topic || '全部'] = Number(r.cnt) || 0;
      }

      const satisfiedIds = evaluateArenaAchievements({
        stats,
        session: sessionPayload,
        totalCorrect,
        topicSessionCounts,
      });
      const newIds = satisfiedIds.filter((id) => !unlockedIds.has(id));

      const nowTs = Date.now();
      for (const achievementId of newIds) {
        await pool.query(
          `INSERT INTO user_achievements (phone, achievement_id, unlocked_at)
           VALUES ($1, $2, $3)
           ON CONFLICT (phone, achievement_id) DO NOTHING`,
          [phone, achievementId, nowTs]
        );
      }

      let newlyUnlocked = [];
      if (newIds.length > 0) {
        const achRes = await pool.query(
          'SELECT id, name, description, icon_key FROM achievements WHERE id = ANY($1)',
          [newIds]
        );
        newlyUnlocked = (achRes.rows || []).map((row) => ({
          id: row.id,
          name: row.name ?? '',
          description: row.description ?? '',
          iconKey: row.icon_key ?? 'star',
        }));
      }

      res.json({
        id: row.id,
        createdAt: row.created_at,
        message: '提交成功',
        newlyUnlocked,
      });
    } catch (err) {
      console.error('[arena challenge submit]', err);
      res.status(500).json({ error: 'server_error', message: '提交失败' });
    }
  });

  // 最近挑战列表（最近 20 次）
  app.get('/arena/challenge/history', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
    try {
      const r = await pool.query(
        `SELECT id, topic, subtopic, total_questions, correct_count, score, created_at
         FROM arena_challenge_sessions
         WHERE phone = $1
         ORDER BY created_at DESC
         LIMIT $2`,
        [phone, limit]
      );
      const list = (r.rows || []).map((row) => ({
        id: row.id,
        topic: row.topic || '全部',
        subtopic: row.subtopic || '全部',
        totalQuestions: row.total_questions,
        correctCount: row.correct_count,
        score: Number(row.score),
        accuracy: row.total_questions > 0 ? row.correct_count / row.total_questions : 0,
        createdAt: row.created_at,
      }));
      res.json({ list });
    } catch (err) {
      console.error('[arena challenge history]', err);
      res.status(500).json({ error: 'server_error', message: '获取挑战记录失败' });
    }
  });

  // 某次挑战详情（题目 + 用户选择 + 正确答案）
  app.get('/arena/challenge/:id', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const id = parseInt(req.params.id, 10);
    if (!id) {
      return res.status(400).json({ error: 'invalid_id', message: '无效的挑战 ID' });
    }
    try {
      const r = await pool.query(
        `SELECT id, phone, topic, subtopic, total_questions, correct_count, score, answers, created_at
         FROM arena_challenge_sessions WHERE id = $1`,
        [id]
      );
      if (!r.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '挑战记录不存在' });
      }
      const row = r.rows[0];
      if (row.phone !== phone) {
        return res.status(403).json({ error: 'forbidden', message: '无权查看' });
      }
      const answers = Array.isArray(row.answers) ? row.answers : (row.answers && typeof row.answers === 'object' && row.answers.length != null ? Array.from(row.answers) : []);
      res.json({
        id: row.id,
        topic: row.topic || '全部',
        subtopic: row.subtopic || '全部',
        totalQuestions: row.total_questions,
        correctCount: row.correct_count,
        score: Number(row.score),
        accuracy: row.total_questions > 0 ? row.correct_count / row.total_questions : 0,
        createdAt: row.created_at,
        answers: answers.map((a) => ({
          questionId: a.questionId ?? a.question_id,
          title: a.title,
          userChoice: a.userChoice ?? a.user_choice,
          correctAnswer: a.correctAnswer ?? a.correct_answer,
          isCorrect: a.isCorrect ?? a.is_correct,
        })),
      });
    } catch (err) {
      console.error('[arena challenge detail]', err);
      res.status(500).json({ error: 'server_error', message: '获取详情失败' });
    }
  });

  // 分区榜（按 topic 在 topic_best 中的分数排序）
  app.get('/arena/leaderboard/zone', optionalAuth, async (req, res) => {
    const topic = req.query.topic && String(req.query.topic).trim();
    const limit = Math.min(parseInt(req.query.limit, 10) || 10, 50);
    const authPhone = req.auth?.phone;
    if (!topic) {
      return res.status(400).json({ error: 'missing_topic', message: '请传入 topic 参数' });
    }
    try {
      const r = await pool.query(
        `SELECT u.phone, u.name, (s.topic_best->>$1)::int AS score
         FROM user_arena_stats s
         JOIN users u ON u.phone = s.phone
         WHERE s.topic_best ? $1 AND (s.topic_best->>$1)::int > 0
         ORDER BY (s.topic_best->>$1)::int DESC NULLS LAST
         LIMIT $2`,
        [topic, limit]
      );
      const list = (r.rows || []).map((row, i) => ({
        rank: i + 1,
        name: row.name || '',
        score: Number(row.score) || 0,
        isMe: !!authPhone && row.phone === authPhone,
      }));
      res.json({ list });
    } catch (err) {
      console.error('[arena leaderboard/zone]', err);
      res.status(500).json({ error: 'server_error', message: '获取分区榜失败' });
    }
  });
}

module.exports = routes;
