const crypto = require('crypto');
const { pool } = require('../db');
const config = require('../config');

const PHONE_REGEX = /^1[3-9]\d{9}$/;
const CODE_REGEX = /^\d{6}$/;

function routes(app) {
  app.post('/auth/send-code', async (req, res) => {
    const phone = (req.body && req.body.phone) ? String(req.body.phone).trim() : '';
    if (!PHONE_REGEX.test(phone)) {
      return res.status(400).json({ error: 'invalid_phone', message: '请输入正确的11位手机号' });
    }
    // 未接短信服务，固定验证码 666666，发送后用户填此码即可
    const code = '666666';
    const expiresAt = Date.now() + config.auth.codeTtlMs;
    try {
      await pool.query(
        `INSERT INTO auth_codes (phone, code, expires_at) VALUES ($1, $2, $3)
         ON CONFLICT (phone) DO UPDATE SET code = $2, expires_at = $3`,
        [phone, code, expiresAt]
      );
      console.log(`[auth] send-code ${phone} -> ${code} (demo)`);
      res.json({ ok: true, demoCode: code });
    } catch (err) {
      console.error('[auth send-code]', err);
      res.status(500).json({ error: 'server_error', message: '发送失败' });
    }
  });

  app.post('/auth/verify', async (req, res) => {
    const phone = (req.body && req.body.phone) ? String(req.body.phone).trim() : '';
    const code = (req.body && req.body.code) ? String(req.body.code).trim() : '';
    if (!PHONE_REGEX.test(phone)) {
      return res.status(400).json({ error: 'invalid_phone', message: '请输入正确的11位手机号' });
    }
    if (!CODE_REGEX.test(code)) {
      return res.status(400).json({ error: 'invalid_code', message: '请输入6位数字验证码' });
    }
    try {
      // 未接短信服务：固定码 666666 可直接通过，无需先调 send-code
      const isDemoCode = code === '666666';
      if (!isDemoCode) {
        const codeRow = await pool.query(
          'SELECT code, expires_at FROM auth_codes WHERE phone = $1',
          [phone]
        );
        if (!codeRow.rows.length) {
          return res.status(400).json({ error: 'code_expired', message: '验证码已过期，请重新获取' });
        }
        const { code: storedCode, expires_at: expiresAt } = codeRow.rows[0];
        if (Number(expiresAt) < Date.now()) {
          await pool.query('DELETE FROM auth_codes WHERE phone = $1', [phone]);
          return res.status(400).json({ error: 'code_expired', message: '验证码已过期，请重新获取' });
        }
        if (storedCode !== code) {
          return res.status(400).json({ error: 'invalid_code', message: '验证码错误' });
        }
        await pool.query('DELETE FROM auth_codes WHERE phone = $1', [phone]);
      }

      let userRow = await pool.query(
        'SELECT phone_number, name, avatar_index, avatar_base64 FROM users WHERE phone = $1',
        [phone]
      );
      if (!userRow.rows.length) {
        const now = Date.now();
        await pool.query(
          `INSERT INTO users (phone, phone_number, name, avatar_index, created_at, updated_at)
           VALUES ($1, $2, $3, 0, $4, $4)`,
          [phone, phone, '星知小探险家', now]
        );
        await pool.query(
          `INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
           VALUES ($1, '20:00', '今天还差 4 项打卡，加油！', $2)
           ON CONFLICT (phone) DO NOTHING`,
          [phone, now]
        );
        await pool.query(
          `INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
           VALUES ($1, 0, 0, 0, 0, 4, $2)
           ON CONFLICT (phone) DO NOTHING`,
          [phone, now]
        );
        userRow = await pool.query(
          'SELECT phone_number, name, avatar_index, avatar_base64 FROM users WHERE phone = $1',
          [phone]
        );
      }
      const user = userRow.rows[0];
      const token = crypto.randomBytes(32).toString('hex');
      await pool.query(
        'INSERT INTO auth_tokens (token, phone, created_at) VALUES ($1, $2, $3)',
        [token, phone, Date.now()]
      );
      console.log(`[auth] verify ok ${phone}`);
      res.json({
        ok: true,
        token,
        user: {
          phoneNumber: user.phone_number,
          name: user.name,
          avatarIndex: user.avatar_index,
          avatarBase64: user.avatar_base64,
        },
      });
    } catch (err) {
      console.error('[auth verify]', err);
      res.status(500).json({ error: 'server_error', message: '验证失败' });
    }
  });
}

module.exports = routes;
