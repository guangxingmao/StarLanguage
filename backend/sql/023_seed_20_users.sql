-- 新增 20 个用户并绑定成长、擂台、成就、社群、打卡等数据
-- 执行顺序：016_fake_data_full_seed、022_arena_topic_best_seed 之后执行
-- 依赖：users, growth_reminder, growth_stats, user_arena_stats, achievements, communities, topics 等表已存在

-- ========== 1. users（20 个新用户） ==========
INSERT INTO users (phone, phone_number, name, avatar_index, created_at, updated_at)
VALUES
  ('13900010010', '13900010010', '星际漫游', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010011', '13900010011', '小小发明家', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010012', '13900010012', '古诗小达人', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010013', '13900010013', '海洋探索者', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010014', '13900010014', '恐龙迷妹', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010015', '13900010015', '棋艺小将', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010016', '13900010016', '环保小卫士', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010017', '13900010017', '舞蹈精灵', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010018', '13900010018', '电影发烧友', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010019', '13900010019', '魔术小学徒', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010020', '13900010020', '瑜伽小树', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010021', '13900010021', '羽毛球小子', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010022', '13900010022', '民俗小传人', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010023', '13900010023', '考古小迷', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010024', '13900010024', '健康小达人', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010025', '13900010025', '宠物萌主', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010026', '13900010026', '手工小匠', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010027', '13900010027', '故事大王', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010028', '13900010028', '跑步小飞侠', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900010029', '13900010029', '游泳小健将', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000)
ON CONFLICT (phone) DO NOTHING;

-- ========== 2. growth_reminder / growth_stats（为新用户补全） ==========
INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
SELECT u.phone, '20:00', '今天还差 3 项打卡，加油！', extract(epoch from now())::bigint * 1000
FROM users u
WHERE u.phone IN (
  '13900010010','13900010011','13900010012','13900010013','13900010014',
  '13900010015','13900010016','13900010017','13900010018','13900010019',
  '13900010020','13900010021','13900010022','13900010023','13900010024',
  '13900010025','13900010026','13900010027','13900010028','13900010029'
)
AND NOT EXISTS (SELECT 1 FROM growth_reminder g WHERE g.phone = u.phone);

INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
SELECT u.phone, (random() * 7)::int, (random() * 40 + 50)::int, (random() * 5)::int, (random() * 4)::int, 4, extract(epoch from now())::bigint * 1000
FROM users u
WHERE u.phone IN (
  '13900010010','13900010011','13900010012','13900010013','13900010014',
  '13900010015','13900010016','13900010017','13900010018','13900010019',
  '13900010020','13900010021','13900010022','13900010023','13900010024',
  '13900010025','13900010026','13900010027','13900010028','13900010029'
)
AND NOT EXISTS (SELECT 1 FROM growth_stats g WHERE g.phone = u.phone);

-- ========== 3. auth_codes（20 条，验证码 666666） ==========
INSERT INTO auth_codes (phone, code, expires_at)
SELECT u.phone, '666666', extract(epoch from now())::bigint + 300
FROM users u
WHERE u.phone IN (
  '13900010010','13900010011','13900010012','13900010013','13900010014',
  '13900010015','13900010016','13900010017','13900010018','13900010019',
  '13900010020','13900010021','13900010022','13900010023','13900010024',
  '13900010025','13900010026','13900010027','13900010028','13900010029'
)
ON CONFLICT (phone) DO UPDATE SET code = EXCLUDED.code, expires_at = EXCLUDED.expires_at;

-- ========== 4. user_arena_stats（20 条 + topic_best） ==========
INSERT INTO user_arena_stats (phone, matches, max_streak, total_score, best_accuracy, topic_best, updated_at)
VALUES
  ('13900010010', 25, 5, 680, 0.82, '{"太空": 195, "天文": 178, "科学": 140}'::jsonb, extract(epoch from now())::bigint),
  ('13900010011', 18, 4, 520, 0.78, '{"发明": 165, "机器人": 152, "计算机": 130}'::jsonb, extract(epoch from now())::bigint),
  ('13900010012', 30, 6, 820, 0.88, '{"语文": 210, "诗歌": 188, "历史": 165}'::jsonb, extract(epoch from now())::bigint),
  ('13900010013', 22, 4, 590, 0.80, '{"海洋": 198, "动物": 172, "自然": 155}'::jsonb, extract(epoch from now())::bigint),
  ('13900010014', 15, 3, 410, 0.72, '{"恐龙": 185, "生物": 160, "考古": 142}'::jsonb, extract(epoch from now())::bigint),
  ('13900010015', 28, 5, 750, 0.85, '{"棋类": 192, "益智": 175, "数学": 158}'::jsonb, extract(epoch from now())::bigint),
  ('13900010016', 12, 2, 320, 0.68, '{"环保": 168, "自然": 145, "健康": 130}'::jsonb, extract(epoch from now())::bigint),
  ('13900010017', 20, 4, 550, 0.79, '{"舞蹈": 182, "音乐": 165, "艺术": 148}'::jsonb, extract(epoch from now())::bigint),
  ('13900010018', 35, 7, 910, 0.90, '{"电影": 205, "动漫": 190, "故事": 168}'::jsonb, extract(epoch from now())::bigint),
  ('13900010019', 14, 3, 380, 0.70, '{"魔术": 155, "科学": 138, "益智": 125}'::jsonb, extract(epoch from now())::bigint),
  ('13900010020', 16, 3, 440, 0.74, '{"瑜伽": 162, "健康": 150, "运动": 135}'::jsonb, extract(epoch from now())::bigint),
  ('13900010021', 26, 5, 710, 0.83, '{"羽毛球": 200, "篮球": 175, "跑步": 152}'::jsonb, extract(epoch from now())::bigint),
  ('13900010022', 19, 4, 500, 0.76, '{"民俗": 178, "历史": 162, "语文": 148}'::jsonb, extract(epoch from now())::bigint),
  ('13900010023', 23, 4, 610, 0.81, '{"考古": 188, "历史": 172, "地理": 155}'::jsonb, extract(epoch from now())::bigint),
  ('13900010024', 21, 4, 570, 0.80, '{"健康": 175, "跑步": 165, "科学": 142}'::jsonb, extract(epoch from now())::bigint),
  ('13900010025', 17, 3, 460, 0.75, '{"宠物": 172, "动物": 158, "自然": 138}'::jsonb, extract(epoch from now())::bigint),
  ('13900010026', 24, 5, 650, 0.82, '{"手工": 185, "美术": 168, "益智": 152}'::jsonb, extract(epoch from now())::bigint),
  ('13900010027', 31, 6, 850, 0.87, '{"故事": 198, "阅读": 182, "语文": 165}'::jsonb, extract(epoch from now())::bigint),
  ('13900010028', 27, 5, 730, 0.84, '{"跑步": 192, "健康": 178, "足球": 155}'::jsonb, extract(epoch from now())::bigint),
  ('13900010029', 29, 6, 780, 0.86, '{"游泳": 205, "健康": 182, "运动": 168}'::jsonb, extract(epoch from now())::bigint)
ON CONFLICT (phone) DO UPDATE SET
  matches = EXCLUDED.matches,
  max_streak = EXCLUDED.max_streak,
  total_score = EXCLUDED.total_score,
  best_accuracy = EXCLUDED.best_accuracy,
  topic_best = EXCLUDED.topic_best,
  updated_at = EXCLUDED.updated_at;

-- ========== 5. user_achievements（每人 1～3 个成就，共约 40 条） ==========
INSERT INTO user_achievements (phone, achievement_id, unlocked_at)
VALUES
  ('13900010010', 'a01', extract(epoch from now())::bigint - 90000),
  ('13900010010', 'a11', extract(epoch from now())::bigint - 80000),
  ('13900010011', 'a01', extract(epoch from now())::bigint - 85000),
  ('13900010011', 'a37', extract(epoch from now())::bigint - 75000),
  ('13900010012', 'a01', extract(epoch from now())::bigint - 92000),
  ('13900010012', 'a21', extract(epoch from now())::bigint - 82000),
  ('13900010012', 'a09', extract(epoch from now())::bigint - 72000),
  ('13900010013', 'a01', extract(epoch from now())::bigint - 88000),
  ('13900010013', 'a08', extract(epoch from now())::bigint - 78000),
  ('13900010014', 'a01', extract(epoch from now())::bigint - 87000),
  ('13900010014', 'a03', extract(epoch from now())::bigint - 77000),
  ('13900010015', 'a01', extract(epoch from now())::bigint - 94000),
  ('13900010015', 'a22', extract(epoch from now())::bigint - 84000),
  ('13900010016', 'a01', extract(epoch from now())::bigint - 81000),
  ('13900010017', 'a01', extract(epoch from now())::bigint - 86000),
  ('13900010017', 'a02', extract(epoch from now())::bigint - 76000),
  ('13900010018', 'a01', extract(epoch from now())::bigint - 95000),
  ('13900010018', 'a04', extract(epoch from now())::bigint - 85000),
  ('13900010018', 'a44', extract(epoch from now())::bigint - 75000),
  ('13900010019', 'a01', extract(epoch from now())::bigint - 79000),
  ('13900010020', 'a01', extract(epoch from now())::bigint - 83000),
  ('13900010020', 'a28', extract(epoch from now())::bigint - 73000),
  ('13900010021', 'a01', extract(epoch from now())::bigint - 91000),
  ('13900010021', 'a06', extract(epoch from now())::bigint - 81000),
  ('13900010022', 'a01', extract(epoch from now())::bigint - 84000),
  ('13900010022', 'a05', extract(epoch from now())::bigint - 74000),
  ('13900010023', 'a01', extract(epoch from now())::bigint - 89000),
  ('13900010023', 'a46', extract(epoch from now())::bigint - 79000),
  ('13900010024', 'a01', extract(epoch from now())::bigint - 86000),
  ('13900010024', 'a30', extract(epoch from now())::bigint - 76000),
  ('13900010025', 'a01', extract(epoch from now())::bigint - 82000),
  ('13900010025', 'a44', extract(epoch from now())::bigint - 72000),
  ('13900010026', 'a01', extract(epoch from now())::bigint - 90000),
  ('13900010026', 'a24', extract(epoch from now())::bigint - 80000),
  ('13900010027', 'a01', extract(epoch from now())::bigint - 93000),
  ('13900010027', 'a46', extract(epoch from now())::bigint - 83000),
  ('13900010027', 'a09', extract(epoch from now())::bigint - 73000),
  ('13900010028', 'a01', extract(epoch from now())::bigint - 88000),
  ('13900010028', 'a06', extract(epoch from now())::bigint - 78000),
  ('13900010029', 'a01', extract(epoch from now())::bigint - 91000),
  ('13900010029', 'a02', extract(epoch from now())::bigint - 81000),
  ('13900010029', 'a17', extract(epoch from now())::bigint - 71000)
ON CONFLICT (phone, achievement_id) DO NOTHING;

-- ========== 6. user_communities（每人 2～4 个社群，共约 55 条） ==========
INSERT INTO user_communities (phone, community_id, joined_at)
VALUES
  ('13900010010', 'space', extract(epoch from now())::bigint - 100000),
  ('13900010010', 'science', extract(epoch from now())::bigint - 95000),
  ('13900010010', 'star', extract(epoch from now())::bigint - 90000),
  ('13900010011', 'robot', extract(epoch from now())::bigint - 98000),
  ('13900010011', 'comp', extract(epoch from now())::bigint - 93000),
  ('13900010011', 'invent', extract(epoch from now())::bigint - 88000),
  ('13900010012', 'chinese', extract(epoch from now())::bigint - 102000),
  ('13900010012', 'poem', extract(epoch from now())::bigint - 97000),
  ('13900010012', 'hist', extract(epoch from now())::bigint - 92000),
  ('13900010013', 'ocean', extract(epoch from now())::bigint - 99000),
  ('13900010013', 'animal', extract(epoch from now())::bigint - 94000),
  ('13900010013', 'nature', extract(epoch from now())::bigint - 89000),
  ('13900010014', 'dinosaur', extract(epoch from now())::bigint - 96000),
  ('13900010014', 'bio', extract(epoch from now())::bigint - 91000),
  ('13900010014', 'archaeo', extract(epoch from now())::bigint - 86000),
  ('13900010015', 'chess', extract(epoch from now())::bigint - 101000),
  ('13900010015', 'puzzle', extract(epoch from now())::bigint - 96000),
  ('13900010015', 'math', extract(epoch from now())::bigint - 91000),
  ('13900010016', 'env', extract(epoch from now())::bigint - 94000),
  ('13900010016', 'nature', extract(epoch from now())::bigint - 89000),
  ('13900010016', 'health', extract(epoch from now())::bigint - 84000),
  ('13900010017', 'dance', extract(epoch from now())::bigint - 97000),
  ('13900010017', 'music', extract(epoch from now())::bigint - 92000),
  ('13900010017', 'art', extract(epoch from now())::bigint - 87000),
  ('13900010018', 'movie', extract(epoch from now())::bigint - 103000),
  ('13900010018', 'cartoon', extract(epoch from now())::bigint - 98000),
  ('13900010018', 'story', extract(epoch from now())::bigint - 93000),
  ('13900010019', 'magic', extract(epoch from now())::bigint - 90000),
  ('13900010019', 'science', extract(epoch from now())::bigint - 85000),
  ('13900010020', 'yoga', extract(epoch from now())::bigint - 92000),
  ('13900010020', 'health', extract(epoch from now())::bigint - 87000),
  ('13900010021', 'badminton', extract(epoch from now())::bigint - 99000),
  ('13900010021', 'sport', extract(epoch from now())::bigint - 94000),
  ('13900010021', 'run', extract(epoch from now())::bigint - 89000),
  ('13900010022', 'folk', extract(epoch from now())::bigint - 95000),
  ('13900010022', 'hist', extract(epoch from now())::bigint - 90000),
  ('13900010022', 'chinese', extract(epoch from now())::bigint - 85000),
  ('13900010023', 'archaeo', extract(epoch from now())::bigint - 97000),
  ('13900010023', 'hist', extract(epoch from now())::bigint - 92000),
  ('13900010023', 'geo', extract(epoch from now())::bigint - 87000),
  ('13900010024', 'health', extract(epoch from now())::bigint - 94000),
  ('13900010024', 'run', extract(epoch from now())::bigint - 89000),
  ('13900010024', 'science', extract(epoch from now())::bigint - 84000),
  ('13900010025', 'pet', extract(epoch from now())::bigint - 91000),
  ('13900010025', 'animal', extract(epoch from now())::bigint - 86000),
  ('13900010026', 'handwork', extract(epoch from now())::bigint - 98000),
  ('13900010026', 'art', extract(epoch from now())::bigint - 93000),
  ('13900010026', 'puzzle', extract(epoch from now())::bigint - 88000),
  ('13900010027', 'story', extract(epoch from now())::bigint - 100000),
  ('13900010027', 'reading', extract(epoch from now())::bigint - 95000),
  ('13900010027', 'chinese', extract(epoch from now())::bigint - 90000),
  ('13900010028', 'run', extract(epoch from now())::bigint - 96000),
  ('13900010028', 'health', extract(epoch from now())::bigint - 91000),
  ('13900010028', 'football', extract(epoch from now())::bigint - 86000),
  ('13900010029', 'swim', extract(epoch from now())::bigint - 99000),
  ('13900010029', 'health', extract(epoch from now())::bigint - 94000),
  ('13900010029', 'run', extract(epoch from now())::bigint - 89000)
ON CONFLICT (phone, community_id) DO NOTHING;

-- ========== 7. growth_daily_completion（部分用户部分任务） ==========
INSERT INTO growth_daily_completion (phone, date, task_id, completed, updated_at)
VALUES
  ('13900010010', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010010', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010012', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010012', to_char(now(), 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900010015', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010018', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010018', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010018', to_char(now(), 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900010021', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint),
  ('13900010024', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010027', to_char(now(), 'YYYY-MM-DD'), 'task_1', true, extract(epoch from now())::bigint),
  ('13900010027', to_char(now(), 'YYYY-MM-DD'), 'task_2', true, extract(epoch from now())::bigint),
  ('13900010029', to_char(now(), 'YYYY-MM-DD'), 'task_3', true, extract(epoch from now())::bigint),
  ('13900010029', to_char(now(), 'YYYY-MM-DD'), 'task_4', true, extract(epoch from now())::bigint)
ON CONFLICT (phone, date, task_id) DO UPDATE SET completed = EXCLUDED.completed, updated_at = EXCLUDED.updated_at;

-- ========== 8. topics（新用户发 5 条话题） ==========
INSERT INTO topics (community_id, title, summary, content, author_phone, author_name, image_url, likes_count, comments_count, created_at)
VALUES
  ('space', '大家看过流星雨吗？', '观星分享', '去年看过英仙座流星雨，超震撼！大家有看过吗？', '13900010010', '星际漫游', NULL, 0, 0, now() - interval '2 hours'),
  ('invent', '用废旧纸箱做了一个小房子', '手工发明', '和爸爸一起用纸箱做了个小房子，可以放玩偶～', '13900010011', '小小发明家', NULL, 0, 0, now() - interval '3 hours'),
  ('poem', '最喜欢的一首古诗', '诗歌分享', '我最喜欢《静夜思》，简单又好记。你们呢？', '13900010012', '古诗小达人', NULL, 0, 0, now() - interval '4 hours'),
  ('ocean', '海底世界纪录片推荐', '海洋话题', '有没有适合小朋友看的海洋纪录片？求推荐！', '13900010013', '海洋探索者', NULL, 0, 0, now() - interval '5 hours'),
  ('dinosaur', '你最喜欢哪种恐龙？', '恐龙迷交流', '我最喜欢霸王龙！你们最喜欢哪种？', '13900010014', '恐龙迷妹', NULL, 0, 0, now() - interval '6 hours');

-- 同步新话题的评论数（若有 topic_comments 关联可后续补充）
-- UPDATE topics SET comments_count = (SELECT COUNT(*)::int FROM topic_comments WHERE topic_id = topics.id);
