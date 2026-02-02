const { requireAuth } = require('../middleware/auth');

function routes(app) {
  app.get('/social/feed', requireAuth, async (_req, res) => {
    try {
      res.json([]);
    } catch (err) {
      console.error('[social feed]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

module.exports = routes;
