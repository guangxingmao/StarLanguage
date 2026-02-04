-- 为 023 新增的 20 个用户补充更多关联数据：话题、点赞、评论、打卡、个人资料、登录 token
-- 执行顺序：023_seed_20_users 之后执行
-- 依赖：topics, topic_likes, topic_comments, growth_daily_completion, users, auth_tokens

-- ========== 1. 更多话题（15 条：用户 13900010015～13900010029 各发 1 条） ==========
INSERT INTO topics (community_id, title, summary, content, author_phone, author_name, image_url, likes_count, comments_count, created_at)
VALUES
  ('chess', '大家平时下什么棋？', '棋类交流', '围棋、象棋、五子棋我都喜欢，你们呢？', '13900010015', '棋艺小将', NULL, 0, 0, now() - interval '7 hours'),
  ('env', '周末去公园捡垃圾', '环保行动', '和同学一起去了公园做环保，很有意义～', '13900010016', '环保小卫士', NULL, 0, 0, now() - interval '8 hours'),
  ('dance', '学了一支新舞', '舞蹈分享', '最近在学街舞，虽然还不熟但很开心！', '13900010017', '舞蹈精灵', NULL, 0, 0, now() - interval '9 hours'),
  ('movie', '推荐一部适合全家看的电影', '电影推荐', '《寻梦环游记》看了好几遍，每次都很感动', '13900010018', '电影发烧友', NULL, 0, 0, now() - interval '10 hours'),
  ('magic', '一个小魔术揭秘', '魔术分享', '用橡皮筋变的小魔术，同学都惊呆了哈哈', '13900010019', '魔术小学徒', NULL, 0, 0, now() - interval '11 hours'),
  ('yoga', '晨起拉伸五分钟', '瑜伽打卡', '早上起来做几个拉伸动作，一整天都精神', '13900010020', '瑜伽小树', NULL, 0, 0, now() - interval '12 hours'),
  ('badminton', '羽毛球双打技巧', '羽毛球交流', '双打时怎么配合跑位？求大神指点', '13900010021', '羽毛球小子', NULL, 0, 0, now() - interval '13 hours'),
  ('folk', '家乡的春节习俗', '民俗分享', '我们老家过年要贴窗花、守岁，你们那儿呢？', '13900010022', '民俗小传人', NULL, 0, 0, now() - interval '14 hours'),
  ('archaeo', '三星堆新发现', '考古趣闻', '看了三星堆的纪录片，古人的智慧太厉害了', '13900010023', '考古小迷', NULL, 0, 0, now() - interval '15 hours'),
  ('health', '早睡早起一周打卡', '健康习惯', '这周坚持 9 点睡 6 点起，感觉状态好多了', '13900010024', '健康小达人', NULL, 0, 0, now() - interval '16 hours'),
  ('pet', '我家猫咪的日常', '宠物日常', '发一张主子的睡姿，萌化啦', '13900010025', '宠物萌主', NULL, 0, 0, now() - interval '17 hours'),
  ('handwork', '折纸小船步骤分享', '手工作品', '跟着教程折了一艘小船，可以漂在水上～', '13900010026', '手工小匠', NULL, 0, 0, now() - interval '18 hours'),
  ('story', '自己编了一个小故事', '故事创作', '给弟弟讲了一个睡前故事，他听得可认真了', '13900010027', '故事大王', NULL, 0, 0, now() - interval '19 hours'),
  ('run', '晨跑 3 公里打卡', '跑步打卡', '今天晨跑完成了，虽然有点累但很爽！', '13900010028', '跑步小飞侠', NULL, 0, 0, now() - interval '20 hours'),
  ('swim', '蛙泳换气练习', '游泳学习', '换气还是不太顺，多练几次会好的', '13900010029', '游泳小健将', NULL, 0, 0, now() - interval '21 hours');

-- ========== 2. topic_likes（20 个用户对若干话题点赞） ==========
-- 对 023 的 5 条话题点赞（按标题绑定，每话题单条用子查询取 id）
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, u.phone, now() - (u.rn::text || ' minutes')::interval
FROM (SELECT id FROM topics WHERE title = '大家看过流星雨吗？' LIMIT 1) t(id)
CROSS JOIN (
  SELECT phone, row_number() OVER () AS rn FROM (VALUES
    ('13900010015'),('13900010016'),('13900010017'),('13900010018'),('13900010019'),
    ('13900010020'),('13900010021'),('13900010022'),('13900010023'),('13900010024')
  ) AS v(phone)
) u
ON CONFLICT (topic_id, user_phone) DO NOTHING;

INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, u.phone, now() - (u.rn::text || ' minutes')::interval
FROM (SELECT id FROM topics WHERE title = '用废旧纸箱做了一个小房子' LIMIT 1) t(id)
CROSS JOIN (SELECT phone, row_number() OVER () AS rn FROM (VALUES ('13900010012'),('13900010013'),('13900010025'),('13900010026'),('13900010027')) AS v(phone)) u
ON CONFLICT (topic_id, user_phone) DO NOTHING;

INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, u.phone, now()
FROM (SELECT id FROM topics WHERE title = '最喜欢的一首古诗' LIMIT 1) t(id)
CROSS JOIN (SELECT phone FROM (VALUES ('13900010010'),('13900010022'),('13900010023')) AS v(phone)) u
ON CONFLICT (topic_id, user_phone) DO NOTHING;

INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, u.phone, now()
FROM (SELECT id FROM topics WHERE title = '海底世界纪录片推荐' LIMIT 1) t(id)
CROSS JOIN (SELECT phone FROM (VALUES ('13900010013'),('13900010014'),('13900010025')) AS v(phone)) u
ON CONFLICT (topic_id, user_phone) DO NOTHING;

INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, u.phone, now()
FROM (SELECT id FROM topics WHERE title = '你最喜欢哪种恐龙？' LIMIT 1) t(id)
CROSS JOIN (SELECT phone FROM (VALUES ('13900010014'),('13900010023'),('13900010011')) AS v(phone)) u
ON CONFLICT (topic_id, user_phone) DO NOTHING;

-- 对新加的 15 条话题部分点赞
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, '13900010010', now() FROM topics t WHERE t.title = '大家平时下什么棋？' AND t.author_phone = '13900010015' LIMIT 1
ON CONFLICT (topic_id, user_phone) DO NOTHING;
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, '13900010011', now() FROM topics t WHERE t.title = '周末去公园捡垃圾' AND t.author_phone = '13900010016' LIMIT 1
ON CONFLICT (topic_id, user_phone) DO NOTHING;
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, '13900010020', now() FROM topics t WHERE t.title = '学了一支新舞' AND t.author_phone = '13900010017' LIMIT 1
ON CONFLICT (topic_id, user_phone) DO NOTHING;
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, '13900010012', now() FROM topics t WHERE t.title = '推荐一部适合全家看的电影' AND t.author_phone = '13900010018' LIMIT 1
ON CONFLICT (topic_id, user_phone) DO NOTHING;
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, '13900010021', now() FROM topics t WHERE t.title = '羽毛球双打技巧' AND t.author_phone = '13900010021' LIMIT 1
ON CONFLICT (topic_id, user_phone) DO NOTHING;
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, '13900010028', now() FROM topics t WHERE t.title = '晨跑 3 公里打卡' AND t.author_phone = '13900010028' LIMIT 1
ON CONFLICT (topic_id, user_phone) DO NOTHING;
INSERT INTO topic_likes (topic_id, user_phone, created_at)
SELECT t.id, '13900010029', now() FROM topics t WHERE t.title = '蛙泳换气练习' AND t.author_phone = '13900010029' LIMIT 1
ON CONFLICT (topic_id, user_phone) DO NOTHING;

-- ========== 3. topic_comments（20 个用户对 023 话题 + 新话题的评论，含二级回复） ==========
-- 023 话题「大家看过流星雨吗？」：3 条一级 + 1 条二级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010015', '棋艺小将', '没看过，今年想去看！', NULL, NULL, now() - interval '1 hour'
FROM topics t WHERE t.title = '大家看过流星雨吗？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010002', '太空爱好者', '英仙座每年 8 月，记得选无光污染的地方', NULL, NULL, now() - interval '50 minutes'
FROM topics t WHERE t.title = '大家看过流星雨吗？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010018', '电影发烧友', '纪录片里看过，现场一定更震撼', NULL, NULL, now() - interval '40 minutes'
FROM topics t WHERE t.title = '大家看过流星雨吗？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT tc.topic_id, '13900010010', '星际漫游', '对，去年就是在郊区看的', tc.id, tc.author_name, now() - interval '35 minutes'
FROM topic_comments tc
INNER JOIN topics t ON t.id = tc.topic_id AND t.title = '大家看过流星雨吗？'
WHERE tc.author_name = '太空爱好者' AND tc.parent_id IS NULL
LIMIT 1;

-- 023 话题「用废旧纸箱做了一个小房子」：2 条一级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010026', '手工小匠', '我们也是用纸箱做过城堡！', NULL, NULL, now() - interval '55 minutes'
FROM topics t WHERE t.title = '用废旧纸箱做了一个小房子' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010016', '环保小卫士', '废物利用赞一个', NULL, NULL, now() - interval '45 minutes'
FROM topics t WHERE t.title = '用废旧纸箱做了一个小房子' LIMIT 1;

-- 023 话题「你最喜欢哪种恐龙？」：2 条一级 + 1 条二级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010023', '考古小迷', '我喜欢三角龙，头盾好帅', NULL, NULL, now() - interval '38 minutes'
FROM topics t WHERE t.title = '你最喜欢哪种恐龙？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010011', '小小发明家', '我更喜欢翼龙，能飞', NULL, NULL, now() - interval '28 minutes'
FROM topics t WHERE t.title = '你最喜欢哪种恐龙？' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT tc.topic_id, '13900010014', '恐龙迷妹', '三角龙+1', tc.id, tc.author_name, now() - interval '18 minutes'
FROM topic_comments tc
INNER JOIN topics t ON t.id = tc.topic_id AND t.title = '你最喜欢哪种恐龙？'
WHERE tc.author_name = '考古小迷' AND tc.parent_id IS NULL
LIMIT 1;

-- 新话题「大家平时下什么棋？」：2 条一级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010009', '历史小迷', '象棋和五子棋都下', NULL, NULL, now() - interval '25 minutes'
FROM topics t WHERE t.title = '大家平时下什么棋？' AND t.author_phone = '13900010015' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010019', '魔术小学徒', '最近在学围棋，好难', NULL, NULL, now() - interval '15 minutes'
FROM topics t WHERE t.title = '大家平时下什么棋？' AND t.author_phone = '13900010015' LIMIT 1;

-- 新话题「推荐一部适合全家看的电影」：2 条一级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010027', '故事大王', '《疯狂动物城》也超好看', NULL, NULL, now() - interval '22 minutes'
FROM topics t WHERE t.title = '推荐一部适合全家看的电影' AND t.author_phone = '13900010018' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010012', '古诗小达人', '我们全家一起看过，哭了好几次', NULL, NULL, now() - interval '12 minutes'
FROM topics t WHERE t.title = '推荐一部适合全家看的电影' AND t.author_phone = '13900010018' LIMIT 1;

-- 新话题「晨跑 3 公里打卡」：2 条一级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010024', '健康小达人', '坚持住，会越来越轻松的', NULL, NULL, now() - interval '20 minutes'
FROM topics t WHERE t.title = '晨跑 3 公里打卡' AND t.author_phone = '13900010028' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010029', '游泳小健将', '明天我也去跑', NULL, NULL, now() - interval '8 minutes'
FROM topics t WHERE t.title = '晨跑 3 公里打卡' AND t.author_phone = '13900010028' LIMIT 1;

-- 新话题「我家猫咪的日常」：2 条一级
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010013', '海洋探索者', '好可爱！我家养鱼哈哈', NULL, NULL, now() - interval '16 minutes'
FROM topics t WHERE t.title = '我家猫咪的日常' AND t.author_phone = '13900010025' LIMIT 1;
INSERT INTO topic_comments (topic_id, author_phone, author_name, content, parent_id, reply_to_author, created_at)
SELECT t.id, '13900010010', '星际漫游', '同款睡姿', NULL, NULL, now() - interval '6 minutes'
FROM topics t WHERE t.title = '我家猫咪的日常' AND t.author_phone = '13900010025' LIMIT 1;

-- 同步话题评论数、点赞数
UPDATE topics t SET comments_count = (SELECT COUNT(*)::int FROM topic_comments WHERE topic_id = t.id);
UPDATE topics t SET likes_count = (SELECT COUNT(*)::int FROM topic_likes WHERE topic_id = t.id);

-- ========== 4. growth_daily_completion 补充（20 个用户多日多任务） ==========
INSERT INTO growth_daily_completion (phone, date, task_id, completed, updated_at)
VALUES
  ('13900010011', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010011', to_char(now(), 'YYYY-MM-DD'), 'task_3', false, extract(epoch from now())::bigint),
  ('13900010013', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010013', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010014', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint),
  ('13900010015', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010015', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010016', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010017', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010017', to_char(now(), 'YYYY-MM-DD'), 'task_4', false, extract(epoch from now())::bigint),
  ('13900010018', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint),
  ('13900010019', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010020', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010020', to_char(now() - interval '1 day', 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900010021', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010022', to_char(now(), 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900010023', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010023', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint),
  ('13900010025', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010026', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010026', to_char(now(), 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900010028', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010028', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint)
ON CONFLICT (phone, date, task_id) DO UPDATE SET completed = EXCLUDED.completed, updated_at = EXCLUDED.updated_at;

-- ========== 5. users 个人资料扩展（level / level_title / level_exp / age / interests） ==========
UPDATE users SET
  level = 2,
  level_title = '星光探索者',
  level_exp = 45,
  age = '10',
  interests = '太空 / 天文 / 科学'
WHERE phone = '13900010010';

UPDATE users SET level = 1, level_title = '初识星辰', level_exp = 78, age = '9',  interests = '发明 / 机器人 / 计算机' WHERE phone = '13900010011';
UPDATE users SET level = 3, level_title = '知识小达人', level_exp = 22, age = '11', interests = '语文 / 诗歌 / 历史' WHERE phone = '13900010012';
UPDATE users SET level = 2, level_title = '星光探索者', level_exp = 60, age = '10', interests = '海洋 / 动物 / 自然' WHERE phone = '13900010013';
UPDATE users SET level = 1, level_title = '初识星辰', level_exp = 90, age = '9',  interests = '恐龙 / 生物 / 考古' WHERE phone = '13900010014';
UPDATE users SET level = 3, level_title = '知识小达人', level_exp = 15, age = '11', interests = '棋类 / 益智 / 数学' WHERE phone = '13900010015';
UPDATE users SET level = 1, level_title = '初识星辰', level_exp = 55, age = '9',  interests = '环保 / 自然 / 健康' WHERE phone = '13900010016';
UPDATE users SET level = 2, level_title = '星光探索者', level_exp = 68, age = '10', interests = '舞蹈 / 音乐 / 艺术' WHERE phone = '13900010017';
UPDATE users SET level = 4, level_title = '智慧星', level_exp = 80, age = '12', interests = '电影 / 动漫 / 故事' WHERE phone = '13900010018';
UPDATE users SET level = 1, level_title = '初识星辰', level_exp = 42, age = '9',  interests = '魔术 / 科学 / 益智' WHERE phone = '13900010019';
UPDATE users SET level = 2, level_title = '星光探索者', level_exp = 30, age = '10', interests = '瑜伽 / 健康 / 运动' WHERE phone = '13900010020';
UPDATE users SET level = 3, level_title = '知识小达人', level_exp = 55, age = '11', interests = '羽毛球 / 篮球 / 跑步' WHERE phone = '13900010021';
UPDATE users SET level = 2, level_title = '星光探索者', level_exp = 48, age = '10', interests = '民俗 / 历史 / 语文' WHERE phone = '13900010022';
UPDATE users SET level = 2, level_title = '星光探索者', level_exp = 72, age = '10', interests = '考古 / 历史 / 地理' WHERE phone = '13900010023';
UPDATE users SET level = 2, level_title = '星光探索者', level_exp = 38, age = '10', interests = '健康 / 跑步 / 科学' WHERE phone = '13900010024';
UPDATE users SET level = 2, level_title = '星光探索者', level_exp = 65, age = '10', interests = '宠物 / 动物 / 自然' WHERE phone = '13900010025';
UPDATE users SET level = 3, level_title = '知识小达人', level_exp = 20, age = '11', interests = '手工 / 美术 / 益智' WHERE phone = '13900010026';
UPDATE users SET level = 3, level_title = '知识小达人', level_exp = 88, age = '11', interests = '故事 / 阅读 / 语文' WHERE phone = '13900010027';
UPDATE users SET level = 3, level_title = '知识小达人', level_exp = 52, age = '11', interests = '跑步 / 健康 / 足球' WHERE phone = '13900010028';
UPDATE users SET level = 3, level_title = '知识小达人', level_exp = 70, age = '11', interests = '游泳 / 健康 / 运动' WHERE phone = '13900010029';

-- ========== 6. auth_tokens（20 个用户各一条，便于登录测试） ==========
INSERT INTO auth_tokens (token, phone, created_at)
SELECT md5(u.phone || '-024-' || extract(epoch from now())::text || u.rn::text || random()::text), u.phone, extract(epoch from now())::bigint
FROM (
  SELECT phone, row_number() OVER () AS rn FROM (VALUES
    ('13900010010'),('13900010011'),('13900010012'),('13900010013'),('13900010014'),
    ('13900010015'),('13900010016'),('13900010017'),('13900010018'),('13900010019'),
    ('13900010020'),('13900010021'),('13900010022'),('13900010023'),('13900010024'),
    ('13900010025'),('13900010026'),('13900010027'),('13900010028'),('13900010029')
  ) AS v(phone)
) u
ON CONFLICT (token) DO NOTHING;
