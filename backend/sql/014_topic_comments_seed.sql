-- 假评论与二级回复（按话题标题绑定，不依赖 topic id 是否为 1、2）
-- 执行顺序：011_topics_seed → 013_topic_comments_reply_schema → 本脚本

-- 话题「为什么猫咪爱晒太阳？」的一级评论
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900001111', '小星星', '我家猫咪每天都要晒太阳！', NULL, NULL, now() - interval '2 hours'
FROM topics t WHERE t.title = '为什么猫咪爱晒太阳？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900002222', '小小动物迷', '因为太阳暖暖的～', NULL, NULL, now() - interval '1 hour'
FROM topics t WHERE t.title = '为什么猫咪爱晒太阳？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900003333', '猫奴一枚', '学到了，谢谢分享', NULL, NULL, now() - interval '45 minutes'
FROM topics t WHERE t.title = '为什么猫咪爱晒太阳？' LIMIT 1;

-- 话题「为什么猫咪爱晒太阳？」的二级回复（回复「小星星」）
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT tc.topic_id, '13900002222', '小小动物迷', '哈哈我家也是！', tc.id, tc.author_name, now() - interval '50 minutes'
FROM topic_comments tc
INNER JOIN topics t ON t.id = tc.topic_id AND t.title = '为什么猫咪爱晒太阳？'
WHERE tc.author_name = '小星星' AND tc.parent_id IS NULL
LIMIT 1;

INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT tc.topic_id, '13800138000', '演示用户', '同感～', tc.id, tc.author_name, now() - interval '30 minutes'
FROM topic_comments tc
INNER JOIN topics t ON t.id = tc.topic_id AND t.title = '为什么猫咪爱晒太阳？'
WHERE tc.author_name = '小星星' AND tc.parent_id IS NULL
LIMIT 1;

-- 话题「你最喜欢的历史人物是谁？」的一级评论
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900004444', '历史控', '我喜欢李白和杜甫！', NULL, NULL, now() - interval '2 hours'
FROM topics t WHERE t.title = '你最喜欢的历史人物是谁？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900005555', '唐宋粉', '苏轼也超有才', NULL, NULL, now() - interval '1 hour'
FROM topics t WHERE t.title = '你最喜欢的历史人物是谁？' LIMIT 1;

-- 话题「你最喜欢的历史人物是谁？」的二级回复（回复「历史控」）
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT tc.topic_id, '13900005555', '唐宋粉', '杜甫的诗读起来特别有画面感', tc.id, tc.author_name, now() - interval '55 minutes'
FROM topic_comments tc
INNER JOIN topics t ON t.id = tc.topic_id AND t.title = '你最喜欢的历史人物是谁？'
WHERE tc.author_name = '历史控' AND tc.parent_id IS NULL
LIMIT 1;

-- 同步所有话题的评论数（使列表显示的 count 与真实一致）
UPDATE topics t SET comments_count = (
  SELECT COUNT(*)::int FROM topic_comments WHERE topic_id = t.id
);
