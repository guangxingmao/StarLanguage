-- 成长页初始数据：为已有用户填充默认提醒与统计（若表中尚无该用户则插入）
-- 在 starknow 库中执行，需先执行 001_schema.sql、002_growth_schema.sql。
-- 默认：每日提醒 20:00、打卡 4 项；连续天数 0、正确率 0%、徽章 0、本周 0/4。

-- 为 users 表中的每个用户插入默认提醒设置（若不存在）
INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
SELECT phone, '20:00', '今天还差 4 项打卡，加油！', extract(epoch from now())::bigint * 1000
FROM users
ON CONFLICT (phone) DO NOTHING;

-- 为 users 表中的每个用户插入默认成长统计（若不存在）：连续 0 天、正确率 0%、徽章 0、本周 0/4
INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
SELECT phone, 0, 0, 0, 0, 4, extract(epoch from now())::bigint * 1000
FROM users
ON CONFLICT (phone) DO NOTHING;
