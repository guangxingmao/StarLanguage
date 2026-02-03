const { requireAuth, optionalAuth } = require('../middleware/auth');
const { pool } = require('../db');

/** GET /communities — 全部社群列表，按热度排序；?q= 按 name 包含搜索；已登录时排除已加入的社群 */
function listAll(app) {
  app.get('/communities', optionalAuth, async (req, res) => {
    const qRaw = req.query.q;
    const q = (qRaw != null && String(qRaw).trim() !== '') ? String(qRaw).trim() : null;
    const phone = (req.auth && req.auth.phone) ? req.auth.phone : null;
    const conditions = [];
    const params = [];
    let paramIndex = 1;

    if (q != null && q !== '') {
      conditions.push(`c.name ILIKE $${paramIndex}`);
      params.push('%' + q + '%');
      paramIndex += 1;
    }
    if (phone != null && phone !== '') {
      conditions.push(`c.id NOT IN (SELECT community_id FROM user_communities WHERE phone = $${paramIndex})`);
      params.push(phone);
      paramIndex += 1;
    }
    const whereClause = conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : '';

    try {
      const r = await pool.query(
        `SELECT c.id, c.name, c.description, c.cover_url, c.sort_order,
                COALESCE(uc.member_count, 0)::int AS member_count
         FROM communities c
         LEFT JOIN (
           SELECT community_id, COUNT(*)::int AS member_count
           FROM user_communities
           GROUP BY community_id
         ) uc ON c.id = uc.community_id
         ${whereClause}
         ORDER BY member_count DESC, c.sort_order ASC, c.id ASC`,
        params
      );
      res.json(
        r.rows.map((row) => ({
          id: row.id,
          name: row.name,
          description: row.description ?? '',
          coverUrl: row.cover_url ?? '',
          sortOrder: row.sort_order ?? 0,
          memberCount: row.member_count ?? 0,
        }))
      );
    } catch (err) {
      console.error('[communities list]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** GET /communities/joined — 当前用户已加入的社群（需登录） */
function listJoined(app) {
  app.get('/communities/joined', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    try {
      const r = await pool.query(
        `SELECT c.id, c.name, c.description, c.cover_url, c.sort_order
         FROM communities c
         INNER JOIN user_communities uc ON uc.community_id = c.id
         WHERE uc.phone = $1
         ORDER BY c.sort_order ASC, c.id ASC`,
        [phone]
      );
      res.json(
        r.rows.map((row) => ({
          id: row.id,
          name: row.name,
          description: row.description ?? '',
          coverUrl: row.cover_url ?? '',
          sortOrder: row.sort_order ?? 0,
        }))
      );
    } catch (err) {
      console.error('[communities joined]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** POST /communities/:id/join — 加入社群（需登录） */
function join(app) {
  app.post('/communities/:id/join', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const communityId = (req.params.id || '').trim();
    if (!communityId) {
      return res.status(400).json({ error: 'invalid_id', message: '社群 id 无效' });
    }
    try {
      const exists = await pool.query('SELECT 1 FROM communities WHERE id = $1', [communityId]);
      if (!exists.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '社群不存在' });
      }
      await pool.query(
        `INSERT INTO user_communities (phone, community_id, joined_at)
         VALUES ($1, $2, $3)
         ON CONFLICT (phone, community_id) DO NOTHING`,
        [phone, communityId, Date.now()]
      );
      res.json({ ok: true, communityId });
    } catch (err) {
      console.error('[communities join]', err);
      res.status(500).json({ error: 'server_error', message: '加入失败' });
    }
  });
}

function routes(app) {
  listAll(app);
  listJoined(app);
  join(app);
}

module.exports = routes;
