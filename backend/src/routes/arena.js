const { requireAuth, optionalAuth } = require('../middleware/auth');
const { pool } = require('../db');

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
      res.json({
        id: row.id,
        createdAt: row.created_at,
        message: '提交成功',
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
