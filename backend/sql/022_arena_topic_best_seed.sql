-- 为 user_arena_stats 补全 topic_best，供分区榜接口使用
-- 依赖：016_fake_data_full_seed 或已有 user_arena_stats 数据

UPDATE user_arena_stats SET topic_best = '{"历史": 235, "计算机": 180, "篮球": 220}'::jsonb WHERE phone = '13800138000';
UPDATE user_arena_stats SET topic_best = '{"历史": 190, "动物": 210, "科学": 165}'::jsonb WHERE phone = '13900001111';
UPDATE user_arena_stats SET topic_best = '{"篮球": 198, "动物": 175}'::jsonb WHERE phone = '13900002222';
UPDATE user_arena_stats SET topic_best = '{"动物": 230, "自然": 140}'::jsonb WHERE phone = '13900003333';
UPDATE user_arena_stats SET topic_best = '{"历史": 205, "地理": 188}'::jsonb WHERE phone = '13900004444';
UPDATE user_arena_stats SET topic_best = '{"历史": 218, "语文": 172}'::jsonb WHERE phone = '13900005555';
UPDATE user_arena_stats SET topic_best = '{"科学": 195, "物理": 160}'::jsonb WHERE phone = '13900006666';
UPDATE user_arena_stats SET topic_best = '{"计算机": 225, "编程": 190}'::jsonb WHERE phone = '13900007777';
UPDATE user_arena_stats SET topic_best = '{"历史": 170, "阅读": 182}'::jsonb WHERE phone = '13900008888';
UPDATE user_arena_stats SET topic_best = '{"篮球": 210, "足球": 155}'::jsonb WHERE phone = '13900009999';
UPDATE user_arena_stats SET topic_best = '{"数学": 200, "阅读": 165}'::jsonb WHERE phone = '13900010001';
UPDATE user_arena_stats SET topic_best = '{"太空": 188, "天文": 172}'::jsonb WHERE phone = '13900010002';
UPDATE user_arena_stats SET topic_best = '{"美食": 175, "自然": 168}'::jsonb WHERE phone = '13900010003';
UPDATE user_arena_stats SET topic_best = '{"摄影": 162, "美术": 178}'::jsonb WHERE phone = '13900010004';
UPDATE user_arena_stats SET topic_best = '{"篮球": 192, "体育": 150}'::jsonb WHERE phone = '13900010005';

-- 未在上的用户也补默认 topic_best，避免分区榜为空（仅当 topic_best 为 null 或 {} 时）
UPDATE user_arena_stats
SET topic_best = jsonb_build_object(
  '历史', (random() * 150 + 80)::int,
  '篮球', (random() * 120 + 60)::int,
  '科学', (random() * 100 + 50)::int,
  '计算机', (random() * 130 + 70)::int
)
WHERE topic_best IS NULL OR topic_best = '{}'::jsonb;
