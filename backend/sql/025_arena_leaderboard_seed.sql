-- 为已有用户补全 user_arena_stats，使知识擂台排行榜有数据
-- 执行顺序：在 002_seed_user、015、016、023 等用户相关种子之后执行
-- 依赖：users、user_arena_stats 表已存在

-- 为所有尚未有擂台统计的用户插入一条记录（总分 > 0 才会出现在排行榜）
INSERT INTO user_arena_stats (phone, matches, max_streak, total_score, best_accuracy, topic_best, updated_at)
SELECT
  u.phone,
  (5 + (random() * 35))::int,
  (1 + (random() * 7))::int,
  (200 + (random() * 1200))::int,
  (0.55 + random() * 0.4)::real,
  jsonb_build_object(
    '历史', (80 + (random() * 120))::int,
    '科学', (70 + (random() * 100))::int,
    '数学', (60 + (random() * 90))::int,
    '篮球', (50 + (random() * 80))::int,
    '动物', (65 + (random() * 95))::int
  ),
  extract(epoch from now())::bigint
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_arena_stats s WHERE s.phone = u.phone)
ON CONFLICT (phone) DO NOTHING;

-- 确保已有记录的用户也有 topic_best（分区榜需要），且 total_score > 0
UPDATE user_arena_stats
SET
  topic_best = COALESCE(NULLIF(topic_best::text, 'null')::jsonb, '{}'::jsonb),
  total_score = CASE WHEN total_score IS NULL OR total_score < 1 THEN (300 + (random() * 800))::int ELSE total_score END,
  updated_at = extract(epoch from now())::bigint
WHERE topic_best IS NULL OR topic_best = 'null'::jsonb OR total_score IS NULL OR total_score < 1;

-- 若 topic_best 仍为空对象，补默认主题分
UPDATE user_arena_stats
SET topic_best = jsonb_build_object(
  '历史', (80 + (random() * 120))::int,
  '科学', (70 + (random() * 100))::int,
  '数学', (60 + (random() * 90))::int
)
WHERE topic_best = '{}'::jsonb OR topic_best IS NULL;
