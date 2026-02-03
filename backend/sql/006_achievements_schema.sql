-- 成就定义表 + 用户已解锁成就（成就墙数据来源）
-- 在 starknow 库中执行，需先有 users 表。

-- 成就主表：每条成就一个唯一 id
CREATE TABLE IF NOT EXISTS achievements (
  id            VARCHAR(20) PRIMARY KEY,
  name          VARCHAR(80) NOT NULL,
  description   VARCHAR(200) NOT NULL DEFAULT '',
  icon_key      VARCHAR(40) NOT NULL DEFAULT 'star',
  category      VARCHAR(40) NOT NULL DEFAULT 'arena',
  sort_order    INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category);
CREATE INDEX IF NOT EXISTS idx_achievements_sort ON achievements(sort_order);

-- 用户已解锁成就：phone + achievement_id 唯一
CREATE TABLE IF NOT EXISTS user_achievements (
  phone          VARCHAR(20) NOT NULL,
  achievement_id VARCHAR(20) NOT NULL,
  unlocked_at    BIGINT NOT NULL,
  PRIMARY KEY (phone, achievement_id),
  FOREIGN KEY (achievement_id) REFERENCES achievements(id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_phone ON user_achievements(phone);
