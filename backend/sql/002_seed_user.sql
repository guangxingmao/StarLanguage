-- 默认演示用户（供 003_growth_seed 为成长页填初始数据；若已有用户可跳过）
-- 执行顺序：001_schema → 002_growth_schema → 本脚本 → 003_growth_seed

INSERT INTO users (phone, phone_number, name, avatar_index, created_at, updated_at)
VALUES (
  '13800138000',
  '13800138000',
  '演示用户',
  0,
  extract(epoch from now())::bigint * 1000,
  extract(epoch from now())::bigint * 1000
)
ON CONFLICT (phone) DO NOTHING;
