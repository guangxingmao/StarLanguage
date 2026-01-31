const { pool } = require('../db');

async function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  const token = auth && auth.startsWith('Bearer ') ? auth.slice(7).trim() : null;
  if (!token) {
    return res.status(401).json({ error: 'unauthorized', message: '请先登录' });
  }
  try {
    const r = await pool.query(
      'SELECT phone FROM auth_tokens WHERE token = $1',
      [token]
    );
    if (!r.rows.length) {
      return res.status(401).json({ error: 'unauthorized', message: '请先登录' });
    }
    req.auth = { phone: r.rows[0].phone };
    next();
  } catch (err) {
    console.error('[auth middleware]', err);
    res.status(500).json({ error: 'server_error', message: '服务异常' });
  }
}

module.exports = { requireAuth };
