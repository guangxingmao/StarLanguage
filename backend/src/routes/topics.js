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

function routes(app) {
  hotToday(app);
  listByCommunity(app);
}

module.exports = routes;
