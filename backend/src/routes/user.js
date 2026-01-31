const { pool } = require('../db');
const { requireAuth } = require('../middleware/auth');

function routes(app) {
  app.get('/user/me', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    try {
      const r = await pool.query(
        'SELECT phone_number, name, avatar_index, avatar_base64 FROM users WHERE phone = $1',
        [phone]
      );
      if (!r.rows.length) {
        return res.status(404).json({ error: 'user_not_found' });
      }
      const u = r.rows[0];
      res.json({
        phoneNumber: u.phone_number,
        name: u.name,
        avatarIndex: u.avatar_index,
        avatarBase64: u.avatar_base64,
      });
    } catch (err) {
      console.error('[user me]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });

  app.patch('/user/me', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const body = req.body || {};
    try {
      const r = await pool.query(
        'SELECT phone_number, name, avatar_index, avatar_base64 FROM users WHERE phone = $1',
        [phone]
      );
      if (!r.rows.length) {
        return res.status(404).json({ error: 'user_not_found' });
      }
      const updates = [];
      const values = [];
      let i = 1;
      if (body.name !== undefined) {
        updates.push(`name = $${i++}`);
        values.push(String(body.name));
      }
      if (body.avatarIndex !== undefined) {
        updates.push(`avatar_index = $${i++}`);
        values.push(Number(body.avatarIndex) || 0);
      }
      if (body.avatarBase64 !== undefined) {
        updates.push(`avatar_base64 = $${i++}`);
        values.push(body.avatarBase64 === null ? null : String(body.avatarBase64));
      }
      if (body.phoneNumber !== undefined) {
        updates.push(`phone_number = $${i++}`);
        values.push(String(body.phoneNumber));
      }
      if (updates.length === 0) {
        const u = r.rows[0];
        return res.json({
          phoneNumber: u.phone_number,
          name: u.name,
          avatarIndex: u.avatar_index,
          avatarBase64: u.avatar_base64,
        });
      }
      updates.push(`updated_at = $${i}`);
      values.push(Date.now());
      values.push(phone);
      await pool.query(
        `UPDATE users SET ${updates.join(', ')} WHERE phone = $${i + 1}`,
        values
      );
      const next = await pool.query(
        'SELECT phone_number, name, avatar_index, avatar_base64 FROM users WHERE phone = $1',
        [phone]
      );
      const u = next.rows[0];
      res.json({
        phoneNumber: u.phone_number,
        name: u.name,
        avatarIndex: u.avatar_index,
        avatarBase64: u.avatar_base64,
      });
    } catch (err) {
      console.error('[user patch]', err);
      res.status(500).json({ error: 'server_error', message: '更新失败' });
    }
  });
}

module.exports = routes;
