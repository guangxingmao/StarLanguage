const { requireAuth } = require('../middleware/auth');
const { pool } = require('../db');

/** 根据 created_at 生成相对时间文案 */
function timeLabel(createdAt) {
  if (!createdAt) return '刚刚';
  const ms = Date.now() - new Date(createdAt).getTime();
  const min = Math.floor(ms / 60000);
  const hour = Math.floor(ms / 3600000);
  const day = Math.floor(ms / 86400000);
  if (min < 1) return '刚刚';
  if (min < 60) return `${min} 分钟前`;
  if (hour < 24) return `${hour} 小时前`;
  if (day < 2) return '昨天';
  if (day < 7) return `${day} 天前`;
  return '更早';
}

/** GET /topics/hot — 今日热门话题：当日发布，按点赞数+评论数总和降序（无需登录） */
function hotToday(app) {
  app.get('/topics/hot', async (_req, res) => {
    try {
      const r = await pool.query(
        `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                t.author_phone, t.author_name, t.image_url,
                t.likes_count, t.comments_count, t.created_at,
                c.name AS community_name
         FROM topics t
         INNER JOIN communities c ON c.id = t.community_id
         WHERE t.created_at::date = current_date
         ORDER BY (t.likes_count + t.comments_count) DESC, t.created_at DESC
         LIMIT 50`
      );
      res.json(
        r.rows.map((row) => ({
          id: String(row.id),
          communityId: row.community_id,
          circle: row.community_name ?? '',
          title: row.title ?? '',
          summary: row.summary ?? '',
          content: row.content ?? '',
          author: row.author_name ?? '',
          timeLabel: timeLabel(row.created_at),
          likes: row.likes_count ?? 0,
          comments: row.comments_count ?? 0,
          imageUrl: row.image_url ?? null,
          createdAt: row.created_at,
        }))
      );
    } catch (err) {
      console.error('[topics hot]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** GET /communities/:id/topics — 指定圈子下的所有话题，按时间倒序（无需登录） */
function listByCommunity(app) {
  app.get('/communities/:id/topics', async (req, res) => {
    const communityId = (req.params.id || '').trim();
    if (!communityId) {
      return res.status(400).json({ error: 'invalid_id', message: '社群 id 无效' });
    }
    try {
      const r = await pool.query(
        `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                t.author_phone, t.author_name, t.image_url,
                t.likes_count, t.comments_count, t.created_at,
                c.name AS community_name
         FROM topics t
         INNER JOIN communities c ON c.id = t.community_id
         WHERE t.community_id = $1
         ORDER BY t.created_at DESC
         LIMIT 100`,
        [communityId]
      );
      res.json(
        r.rows.map((row) => ({
          id: String(row.id),
          communityId: row.community_id,
          circle: row.community_name ?? '',
          title: row.title ?? '',
          summary: row.summary ?? '',
          content: row.content ?? '',
          author: row.author_name ?? '',
          timeLabel: timeLabel(row.created_at),
          likes: row.likes_count ?? 0,
          comments: row.comments_count ?? 0,
          imageUrl: row.image_url ?? null,
          createdAt: row.created_at,
        }))
      );
    } catch (err) {
      console.error('[topics by community]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** POST /topics — 发布话题（需登录） */
function createTopic(app) {
  app.post('/topics', requireAuth, async (req, res) => {
    const { phone } = req.auth;
    const { communityId, title, content, summary, imageUrl } = req.body || {};
    const cid = (communityId != null && communityId !== '') ? String(communityId).trim() : null;
    const titleStr = (title != null && title !== '') ? String(title).trim() : null;
    const contentStr = content != null ? String(content).trim() : '';
    const summaryStr = (summary != null && summary !== '') ? String(summary).trim() : null;
    const imageUrlStr = (imageUrl != null && imageUrl !== '') ? String(imageUrl).trim() : null;

    if (!cid) {
      return res.status(400).json({ error: 'invalid_body', message: '需要 communityId' });
    }
    if (!titleStr) {
      return res.status(400).json({ error: 'invalid_body', message: '需要标题' });
    }

    try {
      const comm = await pool.query('SELECT 1 FROM communities WHERE id = $1', [cid]);
      if (!comm.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '社群不存在' });
      }
      const userRow = await pool.query('SELECT name FROM users WHERE phone = $1', [phone]);
      const authorName = userRow.rows[0]?.name ?? '用户';

      const summaryFinal = summaryStr != null && summaryStr !== ''
        ? summaryStr
        : (contentStr.length > 500 ? contentStr.slice(0, 497) + '...' : contentStr);

      const r = await pool.query(
        `INSERT INTO topics (community_id, title, summary, content, author_phone, author_name, image_url, likes_count, comments_count, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 0, 0, now())
         RETURNING id, community_id, title, summary, content, author_phone, author_name, image_url, likes_count, comments_count, created_at`,
        [cid, titleStr, summaryFinal, contentStr, phone, authorName, imageUrlStr]
      );
      const row = r.rows[0];
      res.status(201).json({
        id: String(row.id),
        communityId: row.community_id,
        circle: (await pool.query('SELECT name FROM communities WHERE id = $1', [cid])).rows[0]?.name ?? '',
        title: row.title,
        summary: row.summary ?? '',
        content: row.content ?? '',
        author: row.author_name ?? '',
        timeLabel: '刚刚',
        likes: row.likes_count ?? 0,
        comments: row.comments_count ?? 0,
        imageUrl: row.image_url ?? null,
        createdAt: row.created_at,
      });
    } catch (err) {
      console.error('[topics create]', err);
      res.status(500).json({ error: 'server_error', message: '发布失败' });
    }
  });
}

function routes(app) {
  hotToday(app);
  listByCommunity(app);
  createTopic(app);
}

module.exports = routes;
