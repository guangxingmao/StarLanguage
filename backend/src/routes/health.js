const config = require('../config');

function routes(app) {
  app.get('/health', (_req, res) => {
    res.json({
      ok: true,
      service: 'starknow-backend',
      aiEnabled: !!(config.tencent.secretId && config.tencent.secretKey),
    });
  });
}

module.exports = routes;
