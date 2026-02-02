-- 擂台成就统计（个人页成就墙数据来源）
-- 在 starknow 库中执行，需先有 users 表。

CREATE TABLE IF NOT EXISTS user_arena_stats (
  phone          VARCHAR(20) PRIMARY KEY,
  matches        INT NOT NULL DEFAULT 0,
  max_streak     INT NOT NULL DEFAULT 0,
  total_score    INT NOT NULL DEFAULT 0,
  best_accuracy  REAL NOT NULL DEFAULT 0,
  topic_best     JSONB DEFAULT '{}',
  updated_at     BIGINT
);

-- topic_best 示例：{"历史": 120, "篮球": 80}
