-- 假用户种子（供社群/话题评论等展示用）
-- 执行顺序：002_seed_user → 本脚本。若 003_growth_seed 已执行，本脚本会为新用户补全 growth 初始行。

INSERT INTO users (phone, phone_number, name, avatar_index, created_at, updated_at)
VALUES
  ('13900001111', '13900001111', '小星星', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900002222', '13900002222', '小小动物迷', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900003333', '13900003333', '猫奴一枚', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900004444', '13900004444', '历史控', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900005555', '13900005555', '唐宋粉', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900006666', '13900006666', '实验室小白', 0, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900007777', '13900007777', '代码星', 1, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000),
  ('13900008888', '13900008888', '星知小记者', 2, extract(epoch from now())::bigint * 1000, extract(epoch from now())::bigint * 1000)
ON CONFLICT (phone) DO NOTHING;

-- 为新用户补全成长提醒与统计（若表存在且该用户尚无记录）
INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
SELECT u.phone, '20:00', '今天还差 4 项打卡，加油！', extract(epoch from now())::bigint * 1000
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM growth_reminder g WHERE g.phone = u.phone);

INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
SELECT u.phone, 0, 0, 0, 0, 4, extract(epoch from now())::bigint * 1000
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM growth_stats g WHERE g.phone = u.phone);
