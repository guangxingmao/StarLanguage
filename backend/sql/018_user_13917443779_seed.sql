-- 用户 13917443779 的「我的」数据：若干话题、我的评论、收到的评论
-- 执行顺序：017_community_topics_seed、014_topic_comments_seed 之后执行
-- 依赖：communities、topics、topic_comments 表及既有种子数据

-- 1. 确保用户存在（若已存在则忽略）
INSERT INTO users (phone, phone_number, name, avatar_index, created_at, updated_at)
VALUES ('13917443779', '13917443779', '星知小探险家', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000)
ON CONFLICT (phone) DO NOTHING;

-- 2. 该用户发的几条话题（用于「我的话题」和「收到的评论」）
INSERT INTO topics (community_id, title, summary, content, author_phone, author_name, image_url, likes_count, comments_count, created_at)
VALUES
  ('animal', '我家狗狗的日常', '萌宠记录', '每天遛狗都能遇到有趣的事，大家有同感吗？', '13917443779', '星知小探险家', NULL, 2, 0, now() - interval '2 days'),
  ('comp', '初学 Python 的小白心得', '编程入门', '刚学完基础语法，感觉循环和列表最难，大家怎么练的？', '13917443779', '星知小探险家', NULL, 1, 0, now() - interval '1 day'),
  ('reading', '最近在读的一本书', '阅读分享', '《小王子》又读了一遍，每次感受都不一样。', '13917443779', '星知小探险家', NULL, 3, 0, now() - interval '3 hours');

-- 3. 「我的评论」：13917443779 在别人话题下的评论
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13917443779', '星知小探险家', '哈哈我家猫也干过！', NULL, NULL, now() - interval '1 day'
FROM topics t WHERE t.title = '你家宠物最搞笑的瞬间' AND t.author_phone != '13917443779' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13917443779', '星知小探险家', '我们是从 Scratch 开始的，孩子很有兴趣。', NULL, NULL, now() - interval '5 hours'
FROM topics t WHERE t.title = '学编程从几岁开始合适？' AND t.author_phone != '13917443779' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13917443779', '星知小探险家', '同问，也想听听大家的经验。', NULL, NULL, now() - interval '2 hours'
FROM topics t WHERE t.title = '暑假书单推荐' AND t.author_phone != '13917443779' LIMIT 1;

-- 4. 「收到的评论」：别人在 13917443779 话题下的评论
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900003333', '猫奴一枚', '有同感！我家狗也是每天戏很多。', NULL, NULL, now() - interval '1 day'
FROM topics t WHERE t.author_phone = '13917443779' AND t.title = '我家狗狗的日常' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900007777', '代码星', '多写小项目练手，比如写个猜数字游戏。', NULL, NULL, now() - interval '12 hours'
FROM topics t WHERE t.author_phone = '13917443779' AND t.title = '初学 Python 的小白心得' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010001', '阅读小书虫', '《小王子》真的常读常新～', NULL, NULL, now() - interval '1 hour'
FROM topics t WHERE t.author_phone = '13917443779' AND t.title = '最近在读的一本书' LIMIT 1;

-- 5. 同步相关话题的评论数
UPDATE topics t SET comments_count = (
  SELECT COUNT(*)::int FROM topic_comments WHERE topic_id = t.id
)
WHERE t.author_phone = '13917443779'
   OR t.id IN (
     SELECT topic_id FROM topic_comments WHERE author_phone = '13917443779'
   );
