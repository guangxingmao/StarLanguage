-- 社群汇总表 + 用户已加入社群（社群页「已加入」数据来源）
-- 在 starknow 库中执行。

-- 社群主表：各兴趣社群
CREATE TABLE IF NOT EXISTS communities (
  id            VARCHAR(32) PRIMARY KEY,
  name          VARCHAR(80) NOT NULL,
  description   VARCHAR(200) DEFAULT '',
  cover_url     VARCHAR(512) DEFAULT '',
  sort_order    INT NOT NULL DEFAULT 0,
  created_at    BIGINT
);

CREATE INDEX IF NOT EXISTS idx_communities_sort ON communities(sort_order);

-- 用户已加入的社群：phone + community_id 唯一
CREATE TABLE IF NOT EXISTS user_communities (
  phone          VARCHAR(20) NOT NULL,
  community_id   VARCHAR(32) NOT NULL,
  joined_at      BIGINT NOT NULL,
  PRIMARY KEY (phone, community_id),
  FOREIGN KEY (community_id) REFERENCES communities(id)
);

CREATE INDEX IF NOT EXISTS idx_user_communities_phone ON user_communities(phone);
