-- 成长页初始数据：为已有用户填充默认提醒与统计（若表中尚无该用户则插入）
-- 在 starknow 库中执行，需先执行 001_schema.sql、002_growth_schema.sql。

-- 为 users 表中的每个用户插入默认提醒设置（若不存在）
INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
SELECT phone, '20:00', '今天还差 3 项打卡，加油！', extract(epoch from now())::bigint * 1000
FROM users
ON CONFLICT (phone) DO NOTHING;

-- 为 users 表中的每个用户插入默认成长统计（若不存在），示例：连续 7 天、正确率 86%、徽章 9、本周 3/5
INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
SELECT phone, 7, 86, 9, 3, 5, extract(epoch from now())::bigint * 1000
FROM users
ON CONFLICT (phone) DO NOTHING;
