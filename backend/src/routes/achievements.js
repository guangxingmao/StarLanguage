const { requireAuth } = require('../middleware/auth');
const { pool } = require('../db');

/** GET /achievements — 全部成就列表（无需登录，供前端成就墙展示） */
function listAll(app) {
  app.get('/achievements', async (_req, res) => {
    try {
      const r = await pool.query(
        'SELECT id, name, description, icon_key, category, sort_order FROM achievements ORDER BY sort_order ASC, id ASC'
      );
      res.json(
        r.rows.map((row) => ({
          id: row.id,
          name: row.name,
          description: row.description ?? '',
          iconKey: row.icon_key ?? 'star',
          category: row.category ?? 'arena',
          sortOrder: row.sort_order ?? 0,
        }))
      );
    } catch (err) {
      console.error('[achievements list]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** GET /user/achievements — 当前用户已解锁的成就 id 列表（需登录） */
function listUnlocked(app) {
  app.get('/user/achievements', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    try {
      const r = await pool.query(
        'SELECT achievement_id FROM user_achievements WHERE phone = $1 ORDER BY unlocked_at ASC',
        [phone]
      );
      res.json({
        unlockedIds: r.rows.map((row) => row.achievement_id),
      });
    } catch (err) {
      console.error('[user achievements]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** POST /user/achievements — 解锁成就（内部或擂台结算时调用，需登录） */
function unlock(app) {
  app.post('/user/achievements', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const { achievementId } = req.body || {};
    if (!achievementId || typeof achievementId !== 'string') {
      return res.status(400).json({ error: 'invalid_body', message: '需要 achievementId' });
    }
    const id = String(achievementId).trim();
    try {
      const exists = await pool.query('SELECT 1 FROM achievements WHERE id = $1', [id]);
      if (!exists.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '成就不存在' });
      }
      await pool.query(
        `INSERT INTO user_achievements (phone, achievement_id, unlocked_at)
         VALUES ($1, $2, $3)
         ON CONFLICT (phone, achievement_id) DO NOTHING`,
        [phone, id, Date.now()]
      );
      res.json({ ok: true, achievementId: id });
    } catch (err) {
      console.error('[user achievements unlock]', err);
      res.status(500).json({ error: 'server_error', message: '解锁失败' });
    }
  });
}

function routes(app) {
  listAll(app);
  listUnlocked(app);
  unlock(app);
}

module.exports = routes;
