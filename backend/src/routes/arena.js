const { requireAuth, optionalAuth } = require('../middleware/auth');
const { pool } = require('../db');

function routes(app) {
  // 题库列表（可不登录访问）；?topic=历史 按主题筛选
  app.get('/arena/questions', async (req, res) => {
    const topic = req.query.topic && String(req.query.topic).trim();
    try {
      let r;
      if (topic && topic !== '全部') {
        r = await pool.query(
          'SELECT id, topic, subtopic, title, options, answer FROM arena_questions WHERE topic = $1 ORDER BY id',
          [topic]
        );
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
        'SELECT matches, max_streak, total_score, best_accuracy, topic_best FROM user_arena_stats WHERE phone = $1',
        [phone]
      );
      if (!r.rows.length) {
        return res.json({
          matches: 0,
          maxStreak: 0,
          totalScore: 0,
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
        bestAccuracy: Number(row.best_accuracy) ?? 0,
        topicBest,
      });
    } catch (err) {
      console.error('[arena stats]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });

  // 在线 PK 排行 / 个人积分排行（按 total_score 排序，可选鉴权以标记 isMe）
  app.get('/arena/leaderboard/score', optionalAuth, async (req, res) => {
    const limit = Math.min(parseInt(req.query.limit, 10) || 10, 50);
    const authPhone = req.auth?.phone;
    try {
      const r = await pool.query(
        `SELECT u.phone, u.name, s.total_score AS score
         FROM user_arena_stats s
         JOIN users u ON u.phone = s.phone
         ORDER BY s.total_score DESC NULLS LAST
         LIMIT $1`,
        [limit]
      );
      const list = (r.rows || []).map((row, i) => ({
        rank: i + 1,
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
