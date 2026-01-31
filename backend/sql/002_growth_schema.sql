-- 成长页相关表（当前 backend 用内存存储，后续可迁到此）
-- 在 starknow 库中执行，可与 001_schema.sql 共用同一库。

-- 用户提醒设置
CREATE TABLE IF NOT EXISTS growth_reminder (
  phone          VARCHAR(20) PRIMARY KEY,
  reminder_time  VARCHAR(10) NOT NULL DEFAULT '20:00',
  message        VARCHAR(200) DEFAULT '',
  updated_at     BIGINT
);

-- 用户成长统计
CREATE TABLE IF NOT EXISTS growth_stats (
  phone             VARCHAR(20) PRIMARY KEY,
  streak_days       INT NOT NULL DEFAULT 0,
  accuracy_percent  INT NOT NULL DEFAULT 0,
  badge_count       INT NOT NULL DEFAULT 0,
  weekly_done       INT NOT NULL DEFAULT 0,
  weekly_total      INT NOT NULL DEFAULT 5,
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
