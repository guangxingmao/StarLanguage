const { pool } = require('../db');
const { requireAuth } = require('../middleware/auth');

function routes(app) {
  app.get('/user/me', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    try {
      const [userRow, reminderRow] = await Promise.all([
        pool.query(
          `SELECT phone_number, name, avatar_index, avatar_base64,
                  age, interests, level, level_title, level_exp, privacy
           FROM users WHERE phone = $1`,
          [phone]
        ),
        pool.query(
          'SELECT reminder_time FROM growth_reminder WHERE phone = $1',
          [phone]
        ),
      ]);
      if (!userRow.rows.length) {
        return res.status(404).json({ error: 'user_not_found' });
      }
      const u = userRow.rows[0];
      const reminderTime = reminderRow.rows[0]?.reminder_time ?? '20:00';
      res.json({
        phoneNumber: u.phone_number,
        name: u.name,
        avatarIndex: u.avatar_index,
        avatarBase64: u.avatar_base64,
        age: u.age ?? null,
        interests: u.interests ?? null,
        level: u.level ?? 1,
        levelTitle: u.level_title ?? null,
        levelExp: u.level_exp ?? 0,
        privacy: u.privacy ?? 'default',
        reminderTime,
        friendCount: 0,
        pendingRequestCount: 0,
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
        `SELECT phone_number, name, avatar_index, avatar_base64,
                age, interests, level, level_title, level_exp, privacy
         FROM users WHERE phone = $1`,
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
      if (body.age !== undefined) {
        updates.push(`age = $${i++}`);
        values.push(body.age === null ? null : String(body.age));
      }
      if (body.interests !== undefined) {
        updates.push(`interests = $${i++}`);
        values.push(body.interests === null ? null : String(body.interests));
      }
      if (body.level !== undefined) {
        updates.push(`level = $${i++}`);
        values.push(Math.max(1, Number(body.level) || 1));
      }
      if (body.levelTitle !== undefined) {
        updates.push(`level_title = $${i++}`);
        values.push(body.levelTitle === null ? null : String(body.levelTitle));
      }
      if (body.levelExp !== undefined) {
        updates.push(`level_exp = $${i++}`);
        values.push(Math.max(0, Number(body.levelExp) || 0));
      }
      if (body.privacy !== undefined) {
        updates.push(`privacy = $${i++}`);
        values.push(body.privacy === null ? 'default' : String(body.privacy));
      }
      if (updates.length === 0) {
        const u = r.rows[0];
        const reminderRow = await pool.query(
          'SELECT reminder_time FROM growth_reminder WHERE phone = $1',
          [phone]
        );
        const reminderTime = reminderRow.rows[0]?.reminder_time ?? '20:00';
        return res.json({
          phoneNumber: u.phone_number,
          name: u.name,
          avatarIndex: u.avatar_index,
          avatarBase64: u.avatar_base64,
          age: u.age ?? null,
          interests: u.interests ?? null,
          level: u.level ?? 1,
          levelTitle: u.level_title ?? null,
          levelExp: u.level_exp ?? 0,
          privacy: u.privacy ?? 'default',
          reminderTime,
          friendCount: 0,
          pendingRequestCount: 0,
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
        `SELECT phone_number, name, avatar_index, avatar_base64,
                age, interests, level, level_title, level_exp, privacy
         FROM users WHERE phone = $1`,
        [phone]
      );
      const u = next.rows[0];
      const reminderRow = await pool.query(
        'SELECT reminder_time FROM growth_reminder WHERE phone = $1',
        [phone]
      );
      const reminderTime = reminderRow.rows[0]?.reminder_time ?? '20:00';
      res.json({
        phoneNumber: u.phone_number,
        name: u.name,
        avatarIndex: u.avatar_index,
        avatarBase64: u.avatar_base64,
        age: u.age ?? null,
        interests: u.interests ?? null,
        level: u.level ?? 1,
        levelTitle: u.level_title ?? null,
        levelExp: u.level_exp ?? 0,
        privacy: u.privacy ?? 'default',
        reminderTime,
        friendCount: 0,
        pendingRequestCount: 0,
      });
    } catch (err) {
      console.error('[user patch]', err);
      res.status(500).json({ error: 'server_error', message: '更新失败' });
    }
  });
}

module.exports = routes;
