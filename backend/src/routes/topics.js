const { requireAuth, optionalAuth } = require('../middleware/auth');
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

/** 将话题行转为 API 对象，可选 likedByMe */
function rowToTopic(row, likedByMe = false) {
  return {
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
    likedByMe: !!likedByMe,
  };
}

/** GET /topics/hot — 今日热门话题；已登录时带 likedByMe */
function hotToday(app) {
  app.get('/topics/hot', optionalAuth, async (req, res) => {
    const phone = req.auth?.phone || null;
    try {
      const sql = phone
        ? `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  t.likes_count, t.comments_count, t.created_at,
                  c.name AS community_name,
                  (SELECT 1 FROM topic_likes tl WHERE tl.topic_id = t.id AND tl.user_phone = $1) AS liked_by_me
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.created_at::date = current_date
           ORDER BY (t.likes_count + t.comments_count) DESC, t.created_at DESC
           LIMIT 50`
        : `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  t.likes_count, t.comments_count, t.created_at,
                  c.name AS community_name
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.created_at::date = current_date
           ORDER BY (t.likes_count + t.comments_count) DESC, t.created_at DESC
           LIMIT 50`;
      const r = phone
        ? await pool.query(sql, [phone])
        : await pool.query(sql);
      res.json(
        r.rows.map((row) => rowToTopic(row, row.liked_by_me != null))
      );
    } catch (err) {
      console.error('[topics hot]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** GET /communities/:id/topics — 指定圈子下的所有话题；已登录时带 likedByMe */
function listByCommunity(app) {
  app.get('/communities/:id/topics', optionalAuth, async (req, res) => {
    const communityId = (req.params.id || '').trim();
    const phone = req.auth?.phone || null;
    if (!communityId) {
      return res.status(400).json({ error: 'invalid_id', message: '社群 id 无效' });
    }
    try {
      const sql = phone
        ? `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  t.likes_count, t.comments_count, t.created_at,
                  c.name AS community_name,
                  (SELECT 1 FROM topic_likes tl WHERE tl.topic_id = t.id AND tl.user_phone = $2) AS liked_by_me
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.community_id = $1
           ORDER BY t.created_at DESC
           LIMIT 100`
        : `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  t.likes_count, t.comments_count, t.created_at,
                  c.name AS community_name
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.community_id = $1
           ORDER BY t.created_at DESC
           LIMIT 100`;
      const r = phone
        ? await pool.query(sql, [communityId, phone])
        : await pool.query(sql, [communityId]);
      res.json(
        r.rows.map((row) => rowToTopic(row, row.liked_by_me != null))
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

/** GET /topics/:id — 话题详情，带 likedByMe 与评论列表（已登录时 likedByMe 有效） */
function getById(app) {
  app.get('/topics/:id', optionalAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const phone = req.auth?.phone || null;
    if (!topicId) {
      return res.status(400).json({ error: 'invalid_id', message: '话题 id 无效' });
    }
    const idNum = parseInt(topicId, 10);
    if (Number.isNaN(idNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题 id 无效' });
    }
    try {
      const topicSql = phone
        ? `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  t.likes_count, t.comments_count, t.created_at,
                  c.name AS community_name,
                  (SELECT 1 FROM topic_likes tl WHERE tl.topic_id = t.id AND tl.user_phone = $2) AS liked_by_me
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.id = $1`
        : `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  t.likes_count, t.comments_count, t.created_at,
                  c.name AS community_name
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.id = $1`;
      const topicRows = phone
        ? await pool.query(topicSql, [idNum, phone])
        : await pool.query(topicSql, [idNum]);
      if (!topicRows.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '话题不存在' });
      }
      const row = topicRows.rows[0];
      const commentsRows = await pool.query(
        `SELECT author_name AS author, content, created_at
         FROM topic_comments
         WHERE topic_id = $1
         ORDER BY created_at ASC`,
        [idNum]
      );
      const comments = commentsRows.rows.map((c) => ({
        author: c.author ?? '',
        content: c.content ?? '',
        timeLabel: timeLabel(c.created_at),
      }));
      res.json({
        ...rowToTopic(row, row.liked_by_me != null),
        comments,
      });
    } catch (err) {
      console.error('[topics getById]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** POST /topics/:id/like — 点赞（需登录） */
function likeTopic(app) {
  app.post('/topics/:id/like', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const { phone } = req.auth;
    const idNum = parseInt(topicId, 10);
    if (!topicId || Number.isNaN(idNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题 id 无效' });
    }
    try {
      const exists = await pool.query('SELECT 1 FROM topics WHERE id = $1', [idNum]);
      if (!exists.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '话题不存在' });
      }
      await pool.query(
        `INSERT INTO topic_likes (topic_id, user_phone) VALUES ($1, $2)
         ON CONFLICT (topic_id, user_phone) DO NOTHING`,
        [idNum, phone]
      );
      const countResult = await pool.query(
        'SELECT COUNT(*) AS n FROM topic_likes WHERE topic_id = $1',
        [idNum]
      );
      const newCount = parseInt(countResult.rows[0]?.n ?? '0', 10);
      await pool.query(
        'UPDATE topics SET likes_count = $1 WHERE id = $2',
        [newCount, idNum]
      );
      res.json({ liked: true, likes: newCount });
    } catch (err) {
      console.error('[topics like]', err);
      res.status(500).json({ error: 'server_error', message: '点赞失败' });
    }
  });
}

/** DELETE /topics/:id/like — 取消点赞（需登录） */
function unlikeTopic(app) {
  app.delete('/topics/:id/like', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const { phone } = req.auth;
    const idNum = parseInt(topicId, 10);
    if (!topicId || Number.isNaN(idNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题 id 无效' });
    }
    try {
      await pool.query(
        'DELETE FROM topic_likes WHERE topic_id = $1 AND user_phone = $2',
        [idNum, phone]
      );
      const countResult = await pool.query(
        'SELECT COUNT(*) AS n FROM topic_likes WHERE topic_id = $1',
        [idNum]
      );
      const newCount = parseInt(countResult.rows[0]?.n ?? '0', 10);
      await pool.query(
        'UPDATE topics SET likes_count = $1 WHERE id = $2',
        [newCount, idNum]
      );
      res.json({ liked: false, likes: newCount });
    } catch (err) {
      console.error('[topics unlike]', err);
      res.status(500).json({ error: 'server_error', message: '取消点赞失败' });
    }
  });
}

/** POST /topics/:id/comments — 发表评论（需登录） */
function addComment(app) {
  app.post('/topics/:id/comments', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const { phone } = req.auth;
    const { content } = req.body || {};
    const contentStr = content != null ? String(content).trim() : '';
    const idNum = parseInt(topicId, 10);
    if (!topicId || Number.isNaN(idNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题 id 无效' });
    }
    if (!contentStr) {
      return res.status(400).json({ error: 'invalid_body', message: '需要评论内容' });
    }
    try {
      const exists = await pool.query('SELECT 1 FROM topics WHERE id = $1', [idNum]);
      if (!exists.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '话题不存在' });
      }
      const userRow = await pool.query('SELECT name FROM users WHERE phone = $1', [phone]);
      const authorName = userRow.rows[0]?.name ?? '用户';
      const ins = await pool.query(
        `INSERT INTO topic_comments (topic_id, author_phone, author_name, content, created_at)
         VALUES ($1, $2, $3, $4, now())
         RETURNING id, author_name, content, created_at`,
        [idNum, phone, authorName, contentStr]
      );
      const commentRow = ins.rows[0];
      await pool.query(
        'UPDATE topics SET comments_count = comments_count + 1 WHERE id = $1',
        [idNum]
      );
      res.status(201).json({
        author: commentRow.author_name ?? '',
        content: commentRow.content ?? '',
        timeLabel: '刚刚',
      });
    } catch (err) {
      console.error('[topics addComment]', err);
      res.status(500).json({ error: 'server_error', message: '评论失败' });
    }
  });
}

function routes(app) {
  hotToday(app);
  getById(app);
  listByCommunity(app);
  createTopic(app);
  likeTopic(app);
  unlikeTopic(app);
  addComment(app);
}

module.exports = routes;
