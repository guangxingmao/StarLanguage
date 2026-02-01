-- 成长页相关表（与 backend growth 接口对应）
-- 在 starknow 库中执行，可与 001_schema.sql 共用同一库。
-- 用户注册后应由后端插入默认行：每日提醒 20:00、打卡固定 4 项；连续天数/正确率/徽章均为 0。

-- 用户提醒设置（默认 20:00，打卡固定 4 项）
CREATE TABLE IF NOT EXISTS growth_reminder (
  phone          VARCHAR(20) PRIMARY KEY,
  reminder_time  VARCHAR(10) NOT NULL DEFAULT '20:00',
  message        VARCHAR(200) DEFAULT '今天还差 4 项打卡，加油！',
  updated_at     BIGINT
);

-- 用户成长统计（默认连续 0 天、正确率 0%、徽章 0、本周 0/4）
CREATE TABLE IF NOT EXISTS growth_stats (
  phone             VARCHAR(20) PRIMARY KEY,
  streak_days       INT NOT NULL DEFAULT 0,
  accuracy_percent  INT NOT NULL DEFAULT 0,
  badge_count       INT NOT NULL DEFAULT 0,
  weekly_done       INT NOT NULL DEFAULT 0,
  weekly_total      INT NOT NULL DEFAULT 4,
  updated_at        BIGINT
);

-- 每日任务完成记录（按日，便于按日重置）
CREATE TABLE IF NOT EXISTS growth_daily_completion (
  phone       VARCHAR(20) NOT NULL,
  date        VARCHAR(10) NOT NULL,
  task_id     VARCHAR(32) NOT NULL,
  completed   BOOLEAN NOT NULL DEFAULT false,
  updated_at  BIGINT,
  PRIMARY KEY (phone, date, task_id)
);

CREATE INDEX IF NOT EXISTS idx_growth_daily_date ON growth_daily_completion(phone, date);
