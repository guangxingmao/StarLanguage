const { requireAuth } = require('../middleware/auth');
const { pool } = require('../db');

function routes(app) {
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
}

module.exports = routes;
