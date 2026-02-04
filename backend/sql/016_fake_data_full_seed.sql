-- 001-015 相关表假数据补全（每表约 10-20 条，含关联）
-- 执行顺序：015_users_seed → 014_topic_comments_seed → 本脚本
-- 依赖：users, communities, topics, achievements 等已存在

-- ========== 1. users 补充（再增 10 个，共约 19 个） ==========
INSERT INTO users (phone, phone_number, name, avatar_index, created_at, updated_at)
VALUES
  ('13900009999', '13900009999', '数学小天才', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010001', '13900010001', '阅读小书虫', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010002', '13900010002', '太空爱好者', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010003', '13900010003', '美食小当家', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010004', '13900010004', '摄影小达人', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010005', '13900010005', '篮球小将', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010006', '13900010006', '英语小能手', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010007', '13900010007', '画画小达人', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010008', '13900010008', '科学探索者', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010009', '13900010009', '历史小迷', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000)
ON CONFLICT (phone) DO NOTHING;

-- ========== 2. auth_codes（15 条，关联已有用户手机号） ==========
INSERT INTO auth_codes (phone, code, expires_at)
SELECT u.phone, '123456', extract(epoch from now())::bigint + 300
FROM (SELECT phone FROM users ORDER BY phone LIMIT 15) u
ON CONFLICT (phone) DO UPDATE SET code = EXCLUDED.code, expires_at = EXCLUDED.expires_at;

-- ========== 3. auth_tokens（15 条） ==========
INSERT INTO auth_tokens (token, phone, created_at)
SELECT md5(u.phone || '-' || u.rn::text || '-' || extract(epoch from now())::text || random()::text), u.phone, extract(epoch from now())::bigint
FROM (SELECT phone, row_number() OVER () AS rn FROM users ORDER BY phone LIMIT 15) u
ON CONFLICT (token) DO NOTHING;

-- ========== 4. growth_reminder / growth_stats（为新用户补全） ==========
INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
SELECT u.phone, '20:00', '今天还差 4 项打卡，加油！', extract(epoch from now())::bigint * 1000
FROM users u WHERE NOT EXISTS (SELECT 1 FROM growth_reminder g WHERE g.phone = u.phone);

INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
SELECT u.phone, 0, 0, 0, 0, 4, extract(epoch from now())::bigint * 1000
FROM users u WHERE NOT EXISTS (SELECT 1 FROM growth_stats g WHERE g.phone = u.phone);

-- ========== 5. growth_daily_completion（20 条：多用户多日多任务） ==========
INSERT INTO growth_daily_completion (phone, date, task_id, completed, updated_at)
VALUES
  ('13800138000', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13800138000', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900001111', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900001111', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_2', false, extract(epoch from now())::bigint),
  ('13900002222', to_char(now(), 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900003333', to_char(now(), 'YYYY-MM-DD'), 'task_4', false, extract(epoch from now())::bigint),
  ('13900004444', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900005555', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900005555', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900006666', to_char(now(), 'YYYY-MM-DD'), 'task_2', false, extract(epoch from now())::bigint),
  ('13900007777', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900008888', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint),
  ('13900009999', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010001', to_char(now(), 'YYYY-MM-DD'), 'task_3', false, extract(epoch from now())::bigint),
  ('13900010002', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint),
  ('13900010003', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010004', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010005', to_char(now(), 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900010006', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint),
  ('13900010007', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_1', false, extract(epoch from now())::bigint)
ON CONFLICT (phone, date, task_id) DO UPDATE SET completed = EXCLUDED.completed, updated_at = EXCLUDED.updated_at;

-- ========== 6. user_arena_stats（15 条，关联用户） ==========
INSERT INTO user_arena_stats (phone, matches, max_streak, total_score, best_accuracy, updated_at)
SELECT u.phone, (10 + (random() * 40)::int), (1 + (random() * 8)::int), (100 + (random() * 900)::int), (0.5 + random() * 0.5)::real, extract(epoch from now())::bigint
FROM (SELECT phone FROM users ORDER BY phone LIMIT 15) u
ON CONFLICT (phone) DO UPDATE SET matches = EXCLUDED.matches, max_streak = EXCLUDED.max_streak, total_score = EXCLUDED.total_score, best_accuracy = EXCLUDED.best_accuracy, updated_at = EXCLUDED.updated_at;

-- ========== 7. user_achievements（18 条：用户-成就关联） ==========
INSERT INTO user_achievements (phone, achievement_id, unlocked_at)
VALUES
  ('13800138000', 'a01', extract(epoch from now())::bigint - 100000),
  ('13800138000', 'a07', extract(epoch from now())::bigint - 200000),
  ('13900001111', 'a02', extract(epoch from now())::bigint - 80000),
  ('13900002222', 'a08', extract(epoch from now())::bigint - 90000),
  ('13900003333', 'a03', extract(epoch from now())::bigint - 70000),
  ('13900004444', 'a05', extract(epoch from now())::bigint - 60000),
  ('13900005555', 'a09', extract(epoch from now())::bigint - 50000),
  ('13900006666', 'a20', extract(epoch from now())::bigint - 40000),
  ('13900007777', 'a06', extract(epoch from now())::bigint - 30000),
  ('13900008888', 'a44', extract(epoch from now())::bigint - 120000),
  ('13900009999', 'a21', extract(epoch from now())::bigint - 110000),
  ('13900010001', 'a37', extract(epoch from now())::bigint - 95000),
  ('13900010002', 'a11', extract(epoch from now())::bigint - 88000),
  ('13900010003', 'a28', extract(epoch from now())::bigint - 77000),
  ('13900010004', 'a45', extract(epoch from now())::bigint - 66000),
  ('13900010005', 'a06', extract(epoch from now())::bigint - 55000),
  ('13900010006', 'a23', extract(epoch from now())::bigint - 44000),
  ('13900010007', 'a24', extract(epoch from now())::bigint - 33000)
ON CONFLICT (phone, achievement_id) DO NOTHING;

-- ========== 8. user_communities（18 条：用户-社群关联） ==========
INSERT INTO user_communities (phone, community_id, joined_at)
VALUES
  ('13800138000', 'animal', extract(epoch from now())::bigint - 100000),
  ('13800138000', 'hist', extract(epoch from now())::bigint - 90000),
  ('13900001111', 'animal', extract(epoch from now())::bigint - 80000),
  ('13900002222', 'science', extract(epoch from now())::bigint - 70000),
  ('13900003333', 'comp', extract(epoch from now())::bigint - 60000),
  ('13900004444', 'hist', extract(epoch from now())::bigint - 50000),
  ('13900005555', 'sport', extract(epoch from now())::bigint - 40000),
  ('13900006666', 'science', extract(epoch from now())::bigint - 30000),
  ('13900007777', 'comp', extract(epoch from now())::bigint - 200000),
  ('13900008888', 'animal', extract(epoch from now())::bigint - 150000),
  ('13900009999', 'math', extract(epoch from now())::bigint - 120000),
  ('13900010001', 'reading', extract(epoch from now())::bigint - 110000),
  ('13900010002', 'space', extract(epoch from now())::bigint - 95000),
  ('13900010003', 'cook', extract(epoch from now())::bigint - 88000),
  ('13900010004', 'photo', extract(epoch from now())::bigint - 77000),
  ('13900010005', 'sport', extract(epoch from now())::bigint - 66000),
  ('13900010006', 'english', extract(epoch from now())::bigint - 55000),
  ('13900010007', 'art', extract(epoch from now())::bigint - 44000)
ON CONFLICT (phone, community_id) DO NOTHING;

-- ========== 9. topics 补充（10 条：关联社群与用户） ==========
INSERT INTO topics (community_id, title, summary, content, author_phone, author_name, image_url, likes_count, comments_count, created_at)
VALUES
  ('math', '趣味数学：找规律填数', '一起来找规律～', '大家遇到过哪些有趣的找规律题？分享一下吧！', '13900009999', '数学小天才', NULL, 0, 0, now() - interval '3 hours'),
  ('reading', '最近在读什么书？', '好书推荐', '最近在读的一本书，简单说说感受～', '13900010001', '阅读小书虫', NULL, 0, 0, now() - interval '4 hours'),
  ('space', '你最喜欢哪颗行星？', '宇宙话题', '火星、木星、土星… 你最喜欢哪一颗？为什么？', '13900010002', '太空爱好者', NULL, 0, 0, now() - interval '5 hours'),
  ('cook', '简单快手菜分享', '美食圈', '一道 15 分钟能搞定的菜，求推荐！', '13900010003', '美食小当家', NULL, 0, 0, now() - interval '6 hours'),
  ('photo', '手机拍夕阳技巧', '摄影交流', '用手机怎么拍出好看的夕阳？', '13900010004', '摄影小达人', NULL, 0, 0, now() - interval '7 hours'),
  ('sport', '周末打球约吗', '篮球圈', '周末有人一起打球吗？', '13900010005', '篮球小将', NULL, 0, 0, now() - interval '8 hours'),
  ('english', '每日一句英语', '英语学习', '今天你学了一句什么？', '13900010006', '英语小能手', NULL, 0, 0, now() - interval '9 hours'),
  ('art', '随手涂鸦分享', '美术圈', '今天的随手画～', '13900010007', '画画小达人', NULL, 0, 0, now() - interval '10 hours'),
  ('science', '在家能做的小实验', '科学圈', '不需要复杂器材的小实验有哪些？', '13900010008', '科学探索者', NULL, 0, 0, now() - interval '11 hours'),
  ('hist', '一个冷门历史知识', '历史圈', '分享一个很多人不知道的历史小知识～', '13900010009', '历史小迷', NULL, 0, 0, now() - interval '12 hours');

-- ========== 10. topic_likes（18 条：用户点赞话题） ==========
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, u.phone, now()
FROM (SELECT id FROM topics ORDER BY id LIMIT 6) t
CROSS JOIN (SELECT phone FROM users ORDER BY phone LIMIT 3) u
ON CONFLICT (topic_id, user_phone) DO NOTHING;

-- ========== 11. topic_comments 补充（15 条：多话题一级/二级评论） ==========
-- 话题「哪一刻让你爱上科学？」下 3 条一级评论
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010008', '科学探索者', '第一次做彩虹实验的时候！', NULL, NULL, now() - interval '20 minutes'
FROM topics t WHERE t.title = '哪一刻让你爱上科学？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900006666', '实验室小白', '显微镜看洋葱细胞～', NULL, NULL, now() - interval '15 minutes'
FROM topics t WHERE t.title = '哪一刻让你爱上科学？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010002', '太空爱好者', '看火箭发射直播', NULL, NULL, now() - interval '10 minutes'
FROM topics t WHERE t.title = '哪一刻让你爱上科学？' LIMIT 1;
-- 话题「篮球招式大揭秘」下 2 条一级 + 1 条二级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010005', '篮球小将', '三步上篮练了好久才会', NULL, NULL, now() - interval '25 minutes'
FROM topics t WHERE t.title = '篮球招式大揭秘' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900005555', '唐宋粉', '后仰跳投超帅', NULL, NULL, now() - interval '18 minutes'
FROM topics t WHERE t.title = '篮球招式大揭秘' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT tc.topic_id, '13800138000', '演示用户', '同感，多练就会了', tc.id, tc.author_name, now() - interval '12 minutes'
FROM topic_comments tc
INNER JOIN topics t ON t.id = tc.topic_id AND t.title = '篮球招式大揭秘'
WHERE tc.author_name = '篮球小将' AND tc.parent_id IS NULL LIMIT 1;
-- 话题「我做了个小程序！」下 2 条
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900007777', '代码星', '用 Scratch 做了打地鼠', NULL, NULL, now() - interval '22 minutes'
FROM topics t WHERE t.title = '我做了个小程序！' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900003333', '猫奴一枚', '想学，求教程', NULL, NULL, now() - interval '8 minutes'
FROM topics t WHERE t.title = '我做了个小程序！' LIMIT 1;
-- 新话题「趣味数学：找规律填数」下 3 条
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900009999', '数学小天才', '1,2,4,7,11... 下一个是 16', NULL, NULL, now() - interval '5 minutes'
FROM topics t WHERE t.title = '趣味数学：找规律填数' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010001', '阅读小书虫', '我们班也做过这类题', NULL, NULL, now() - interval '3 minutes'
FROM topics t WHERE t.title = '趣味数学：找规律填数' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010009', '历史小迷', '有意思', NULL, NULL, now() - interval '1 minute'
FROM topics t WHERE t.title = '趣味数学：找规律填数' LIMIT 1;
-- 新话题「最近在读什么书？」下 2 条
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010001', '阅读小书虫', '《小王子》又读了一遍', NULL, NULL, now() - interval '6 minutes'
FROM topics t WHERE t.title = '最近在读什么书？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900008888', '星知小记者', '推荐《夏洛的网》', NULL, NULL, now() - interval '4 minutes'
FROM topics t WHERE t.title = '最近在读什么书？' LIMIT 1;

-- 话题「长城到底有多长？」（011 种子第 6 条，确保有评论可展示）
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010009', '历史小迷', '不同朝代修的长度不一样，现在常说约两万多公里', NULL, NULL, now() - interval '30 minutes'
FROM topics t WHERE t.title = '长城到底有多长？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900004444', '历史控', '明长城东起辽宁虎山，西到甘肃嘉峪关', NULL, NULL, now() - interval '20 minutes'
FROM topics t WHERE t.title = '长城到底有多长？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13800138000', '演示用户', '可以查一下国家文物局的数据～', NULL, NULL, now() - interval '10 minutes'
FROM topics t WHERE t.title = '长城到底有多长？' LIMIT 1;

-- 同步所有话题的评论数
UPDATE topics SET comments_count = (SELECT COUNT(*)::int FROM topic_comments WHERE topic_id = topics.id);
-- 同步所有话题的点赞数
UPDATE topics t SET likes_count = (SELECT COUNT(*)::int FROM topic_likes WHERE topic_id = t.id);
