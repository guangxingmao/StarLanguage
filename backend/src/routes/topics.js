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
                  (SELECT COUNT(*)::int FROM topic_likes tlc WHERE tlc.topic_id = t.id) AS likes_count,
                  (SELECT COUNT(*)::int FROM topic_comments tcc WHERE tcc.topic_id = t.id) AS comments_count,
                  t.created_at,
                  c.name AS community_name,
                  (SELECT 1 FROM topic_likes tl WHERE tl.topic_id = t.id AND tl.user_phone = $1) AS liked_by_me
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.created_at::date = current_date
           ORDER BY (
             (SELECT COUNT(*)::int FROM topic_likes tlc WHERE tlc.topic_id = t.id) +
             (SELECT COUNT(*)::int FROM topic_comments tcc WHERE tcc.topic_id = t.id)
           ) DESC, t.created_at DESC
           LIMIT 50`
        : `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  (SELECT COUNT(*)::int FROM topic_likes tlc WHERE tlc.topic_id = t.id) AS likes_count,
                  (SELECT COUNT(*)::int FROM topic_comments tcc WHERE tcc.topic_id = t.id) AS comments_count,
                  t.created_at,
                  c.name AS community_name
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.created_at::date = current_date
           ORDER BY (
             (SELECT COUNT(*)::int FROM topic_likes tlc WHERE tlc.topic_id = t.id) +
             (SELECT COUNT(*)::int FROM topic_comments tcc WHERE tcc.topic_id = t.id)
           ) DESC, t.created_at DESC
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

/** GET /communities/:id/received-comments — 本圈内「别人给我的评论」（我发的话题下的评论，需登录） */
function getReceivedComments(app) {
  app.get('/communities/:id/received-comments', requireAuth, async (req, res) => {
    const communityId = (req.params.id || '').trim();
    const { phone } = req.auth;
    if (!communityId) {
      return res.status(400).json({ error: 'invalid_id', message: '社群 id 无效' });
    }
    try {
      const r = await pool.query(
        `SELECT tc.id AS comment_id, tc.topic_id, t.title AS topic_title,
                tc.author_name AS author, tc.content, tc.reply_to_author, tc.created_at
         FROM topic_comments tc
         INNER JOIN topics t ON t.id = tc.topic_id AND t.author_phone = $1 AND t.community_id = $2
         WHERE tc.author_phone != $1
         ORDER BY tc.created_at DESC
         LIMIT 50`,
        [phone, communityId]
      );
      res.json(
        r.rows.map((row) => ({
          commentId: row.comment_id,
          topicId: row.topic_id,
          topicTitle: row.topic_title ?? '',
          author: row.author ?? '',
          content: row.content ?? '',
          timeLabel: timeLabel(row.created_at),
          replyToAuthor: row.reply_to_author ?? null,
        }))
      );
    } catch (err) {
      console.error('[topics received-comments]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });
}

/** GET /communities/:id/my-comments — 本圈内「我对别人的评论」（我在别人话题下的评论，需登录） */
function getMyComments(app) {
  app.get('/communities/:id/my-comments', requireAuth, async (req, res) => {
    const communityId = (req.params.id || '').trim();
    const { phone } = req.auth;
    if (!communityId) {
      return res.status(400).json({ error: 'invalid_id', message: '社群 id 无效' });
    }
    try {
      const r = await pool.query(
        `SELECT tc.id AS comment_id, tc.topic_id, t.title AS topic_title,
                tc.author_name AS author, tc.content, tc.reply_to_author, tc.created_at
         FROM topic_comments tc
         INNER JOIN topics t ON t.id = tc.topic_id AND t.community_id = $2 AND t.author_phone != $1
         WHERE tc.author_phone = $1
         ORDER BY tc.created_at DESC
         LIMIT 50`,
        [phone, communityId]
      );
      res.json(
        r.rows.map((row) => ({
          commentId: row.comment_id,
          topicId: row.topic_id,
          topicTitle: row.topic_title ?? '',
          author: row.author ?? '',
          content: row.content ?? '',
          timeLabel: timeLabel(row.created_at),
          replyToAuthor: row.reply_to_author ?? null,
        }))
      );
    } catch (err) {
      console.error('[topics my-comments]', err);
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
                  (SELECT COUNT(*)::int FROM topic_likes tlc WHERE tlc.topic_id = t.id) AS likes_count,
                  (SELECT COUNT(*)::int FROM topic_comments tcc WHERE tcc.topic_id = t.id) AS comments_count,
                  t.created_at,
                  c.name AS community_name,
                  (SELECT 1 FROM topic_likes tl WHERE tl.topic_id = t.id AND tl.user_phone = $2) AS liked_by_me
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.community_id = $1
           ORDER BY t.created_at DESC
           LIMIT 100`
        : `SELECT t.id, t.community_id, t.title, t.summary, t.content,
                  t.author_phone, t.author_name, t.image_url,
                  (SELECT COUNT(*)::int FROM topic_likes tlc WHERE tlc.topic_id = t.id) AS likes_count,
                  (SELECT COUNT(*)::int FROM topic_comments tcc WHERE tcc.topic_id = t.id) AS comments_count,
                  t.created_at,
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
        r.rows.map((row) => ({
          ...rowToTopic(row, row.liked_by_me != null),
          isMine: !!(phone && row.author_phone === phone),
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

/** 将评论行转为 API 对象（含 id、parentId、replyToAuthor、isMine），并组装为树形 replies */
function buildCommentTree(rows, currentUserPhone = null) {
  const byId = new Map();
  const roots = [];
  for (const r of rows) {
    const node = {
      id: r.id,
      author: r.author ?? '',
      content: r.content ?? '',
      timeLabel: timeLabel(r.created_at),
      parentId: r.parent_id ?? null,
      replyToAuthor: r.reply_to_author ?? null,
      isMine: !!(currentUserPhone && r.author_phone === currentUserPhone),
      replies: [],
      _createdAt: r.created_at,
    };
    byId.set(r.id, node);
  }
  for (const r of rows) {
    const node = byId.get(r.id);
    if (r.parent_id == null) {
      roots.push(node);
    } else {
      const parent = byId.get(r.parent_id);
      if (parent) parent.replies.push(node);
      else roots.push(node);
    }
  }
  // 最新在前：一级评论与二级回复均按时间倒序
  roots.sort((a, b) => new Date(b._createdAt || 0) - new Date(a._createdAt || 0));
  roots.forEach((n) => {
    n.replies.sort((a, b) => new Date(b._createdAt || 0) - new Date(a._createdAt || 0));
    delete n._createdAt;
    n.replies.forEach((r) => delete r._createdAt);
  });
  return roots;
}

/** GET /topics/:id — 话题详情，带 isMine、likedByMe、评论树（二级回复） */
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
        ? `SELECT t.id, t.community_id, t.author_phone, t.title, t.summary, t.content,
                  t.author_name, t.image_url, t.likes_count, t.comments_count, t.created_at,
                  c.name AS community_name,
                  (SELECT 1 FROM topic_likes tl WHERE tl.topic_id = t.id AND tl.user_phone = $2) AS liked_by_me
           FROM topics t
           INNER JOIN communities c ON c.id = t.community_id
           WHERE t.id = $1`
        : `SELECT t.id, t.community_id, t.author_phone, t.title, t.summary, t.content,
                  t.author_name, t.image_url, t.likes_count, t.comments_count, t.created_at,
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
      const isMine = !!(phone && row.author_phone === phone);

      let commentList = [];
      try {
        const commentsRows = await pool.query(
          `SELECT id, parent_id, author_phone, author_name AS author, content, reply_to_author, created_at
           FROM topic_comments
           WHERE topic_id = $1
           ORDER BY created_at ASC`,
          [idNum]
        );
        commentList = commentsRows.rows || [];
      } catch (commentErr) {
        console.error('[topics getById] comment query failed', commentErr);
        return res.status(500).json({ error: 'server_error', message: '获取评论失败' });
      }

      const commentTree = buildCommentTree(
        commentList.map((c) => ({ ...c, created_at: c.created_at })),
        phone
      );
      const topicPayload = rowToTopic(row, row.liked_by_me != null);
      // 点赞/评论数以实际查询到的为准，避免 topics.likes_count / topics.comments_count 未同步导致不一致
      const realComments = commentList.length;
      topicPayload.comments = realComments;
      try {
        const likesCountRow = await pool.query('SELECT COUNT(*) AS n FROM topic_likes WHERE topic_id = $1', [idNum]);
        const realLikes = parseInt(likesCountRow.rows[0]?.n ?? '0', 10);
        topicPayload.likes = realLikes;
        if ((row.likes_count ?? 0) !== realLikes || (row.comments_count ?? 0) !== realComments) {
          await pool.query('UPDATE topics SET likes_count = $1, comments_count = $2 WHERE id = $3', [realLikes, realComments, idNum]);
        }
      } catch (syncErr) {
        // 同步失败不影响接口返回（仍返回实时 counts）
        console.error('[topics getById] sync counts failed', syncErr);
      }
      res.json({
        ...topicPayload,
        isMine,
        commentList: commentTree,
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

/** POST /topics/:id/comments — 发表评论或回复（需登录）；body 可含 parentId、replyToAuthor 为二级回复 */
function addComment(app) {
  app.post('/topics/:id/comments', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const { phone } = req.auth;
    const { content, parentId, replyToAuthor } = req.body || {};
    const contentStr = content != null ? String(content).trim() : '';
    const idNum = parseInt(topicId, 10);
    const parentIdNum = parentId != null && parentId !== '' ? parseInt(String(parentId), 10) : null;
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
      if (parentIdNum != null && !Number.isNaN(parentIdNum)) {
        const parentRow = await pool.query(
          'SELECT id, author_phone FROM topic_comments WHERE id = $1 AND topic_id = $2',
          [parentIdNum, idNum]
        );
        if (!parentRow.rows.length) {
          return res.status(400).json({ error: 'invalid_parent', message: '回复的评论不存在' });
        }
        // 只能回复别人的评论：禁止回复自己发表的评论
        if (parentRow.rows[0].author_phone === phone) {
          return res.status(400).json({ error: 'invalid_parent', message: '不能回复自己的评论' });
        }
      }
      const userRow = await pool.query('SELECT name FROM users WHERE phone = $1', [phone]);
      const authorName = userRow.rows[0]?.name ?? '用户';
      const replyToAuthorStr = (replyToAuthor != null && String(replyToAuthor).trim() !== '') ? String(replyToAuthor).trim() : null;
      const ins = await pool.query(
        `INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, now())
         RETURNING id, parent_id, author_name, content, reply_to_author, created_at`,
        [idNum, phone, authorName, contentStr, parentIdNum || null, replyToAuthorStr]
      );
      const commentRow = ins.rows[0];
      // 重新计算评论数，避免层级删除/历史数据导致计数漂移
      const countResult = await pool.query('SELECT COUNT(*) AS n FROM topic_comments WHERE topic_id = $1', [idNum]);
      const newCount = parseInt(countResult.rows[0]?.n ?? '0', 10);
      await pool.query('UPDATE topics SET comments_count = $1 WHERE id = $2', [newCount, idNum]);
      res.status(201).json({
        id: commentRow.id,
        parentId: commentRow.parent_id ?? null,
        replyToAuthor: commentRow.reply_to_author ?? null,
        author: commentRow.author_name ?? '',
        content: commentRow.content ?? '',
        timeLabel: '刚刚',
        replies: [],
        isMine: true,
      });
    } catch (err) {
      console.error('[topics addComment]', err);
      res.status(500).json({ error: 'server_error', message: '评论失败' });
    }
  });
}

/** PUT /topics/:topicId/comments/:commentId — 编辑评论（仅作者） */
function updateComment(app) {
  app.put('/topics/:id/comments/:commentId', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const commentId = (req.params.commentId || '').trim();
    const { phone } = req.auth;
    const { content } = req.body || {};
    const idNum = parseInt(topicId, 10);
    const commentIdNum = parseInt(commentId, 10);
    if (!topicId || Number.isNaN(idNum) || !commentId || Number.isNaN(commentIdNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题或评论 id 无效' });
    }
    const contentStr = content != null ? String(content).trim() : '';
    if (!contentStr) {
      return res.status(400).json({ error: 'invalid_body', message: '需要评论内容' });
    }
    try {
      const commentRow = await pool.query(
        'SELECT id, author_phone, author_name, parent_id, reply_to_author, created_at FROM topic_comments WHERE id = $1 AND topic_id = $2',
        [commentIdNum, idNum]
      );
      if (!commentRow.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '评论不存在' });
      }
      if (commentRow.rows[0].author_phone !== phone) {
        return res.status(403).json({ error: 'forbidden', message: '只能编辑自己的评论' });
      }
      await pool.query('UPDATE topic_comments SET content = $1 WHERE id = $2 AND topic_id = $3', [contentStr, commentIdNum, idNum]);
      const row = commentRow.rows[0];
      res.json({
        id: row.id,
        parentId: row.parent_id ?? null,
        replyToAuthor: row.reply_to_author ?? null,
        author: row.author_name ?? '',
        content: contentStr,
        timeLabel: timeLabel(row.created_at),
        replies: [],
      });
    } catch (err) {
      console.error('[topics updateComment]', err);
      res.status(500).json({ error: 'server_error', message: '更新失败' });
    }
  });
}

/** DELETE /topics/:topicId/comments/:commentId — 删除评论（仅作者） */
function deleteComment(app) {
  app.delete('/topics/:id/comments/:commentId', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const commentId = (req.params.commentId || '').trim();
    const { phone } = req.auth;
    const idNum = parseInt(topicId, 10);
    const commentIdNum = parseInt(commentId, 10);
    if (!topicId || Number.isNaN(idNum) || !commentId || Number.isNaN(commentIdNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题或评论 id 无效' });
    }
    try {
      const commentRow = await pool.query(
        'SELECT id, author_phone, parent_id FROM topic_comments WHERE id = $1 AND topic_id = $2',
        [commentIdNum, idNum]
      );
      if (!commentRow.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '评论不存在' });
      }
      if (commentRow.rows[0].author_phone !== phone) {
        return res.status(403).json({ error: 'forbidden', message: '只能删除自己的评论' });
      }
      await pool.query('DELETE FROM topic_comments WHERE id = $1 AND topic_id = $2', [commentIdNum, idNum]);
      // 可能级联删除多条（二级回复），所以删除后重新计算评论数
      const countResult = await pool.query('SELECT COUNT(*) AS n FROM topic_comments WHERE topic_id = $1', [idNum]);
      const newCount = parseInt(countResult.rows[0]?.n ?? '0', 10);
      await pool.query('UPDATE topics SET comments_count = $1 WHERE id = $2', [newCount, idNum]);
      res.status(204).send();
    } catch (err) {
      console.error('[topics deleteComment]', err);
      res.status(500).json({ error: 'server_error', message: '删除失败' });
    }
  });
}

/** PUT /topics/:id — 编辑话题（仅作者） */
function updateTopic(app) {
  app.put('/topics/:id', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const { phone } = req.auth;
    const { title, content, summary, imageUrl } = req.body || {};
    const idNum = parseInt(topicId, 10);
    if (!topicId || Number.isNaN(idNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题 id 无效' });
    }
    try {
      const topicRow = await pool.query('SELECT id, author_phone FROM topics WHERE id = $1', [idNum]);
      if (!topicRow.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '话题不存在' });
      }
      if (topicRow.rows[0].author_phone !== phone) {
        return res.status(403).json({ error: 'forbidden', message: '只能编辑自己的话题' });
      }
      const titleStr = (title != null && String(title).trim() !== '') ? String(title).trim() : null;
      const contentStr = content != null ? String(content).trim() : null;
      const summaryStr = (summary != null && String(summary).trim() !== '') ? String(summary).trim() : null;
      const imageUrlStr = (imageUrl != null && String(imageUrl).trim() !== '') ? String(imageUrl).trim() : null;
      if (!titleStr) {
        return res.status(400).json({ error: 'invalid_body', message: '需要标题' });
      }
      await pool.query(
        `UPDATE topics SET title = COALESCE($2, title), content = COALESCE($3, content),
                summary = COALESCE($4, summary), image_url = COALESCE($5, image_url)
         WHERE id = $1`,
        [idNum, titleStr, contentStr, summaryStr, imageUrlStr]
      );
      const r = await pool.query(
        `SELECT t.id, t.community_id, t.title, t.summary, t.content, t.author_name, t.image_url,
                t.likes_count, t.comments_count, t.created_at, c.name AS community_name
         FROM topics t INNER JOIN communities c ON c.id = t.community_id WHERE t.id = $1`,
        [idNum]
      );
      const row = r.rows[0];
      res.json(rowToTopic(row, false));
    } catch (err) {
      console.error('[topics update]', err);
      res.status(500).json({ error: 'server_error', message: '更新失败' });
    }
  });
}

/** DELETE /topics/:id — 删除话题（仅作者） */
function deleteTopic(app) {
  app.delete('/topics/:id', requireAuth, async (req, res) => {
    const topicId = (req.params.id || '').trim();
    const { phone } = req.auth;
    const idNum = parseInt(topicId, 10);
    if (!topicId || Number.isNaN(idNum)) {
      return res.status(400).json({ error: 'invalid_id', message: '话题 id 无效' });
    }
    try {
      const topicRow = await pool.query('SELECT id, author_phone FROM topics WHERE id = $1', [idNum]);
      if (!topicRow.rows.length) {
        return res.status(404).json({ error: 'not_found', message: '话题不存在' });
      }
      if (topicRow.rows[0].author_phone !== phone) {
        return res.status(403).json({ error: 'forbidden', message: '只能删除自己的话题' });
      }
      await pool.query('DELETE FROM topics WHERE id = $1', [idNum]);
      res.status(204).send();
    } catch (err) {
      console.error('[topics delete]', err);
      res.status(500).json({ error: 'server_error', message: '删除失败' });
    }
  });
}

function routes(app) {
  hotToday(app);
  getById(app);
  getReceivedComments(app);
  getMyComments(app);
  listByCommunity(app);
  createTopic(app);
  updateTopic(app);
  deleteTopic(app);
  likeTopic(app);
  unlikeTopic(app);
  addComment(app);
  updateComment(app);
  deleteComment(app);
}

module.exports = routes;
