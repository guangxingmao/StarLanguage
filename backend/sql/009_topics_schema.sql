-- 话题表：绑定社群，含点赞数、讨论数，用于今日热门排序
-- 在 starknow 库中执行，需先有 communities 表。

CREATE TABLE IF NOT EXISTS topics (
  id              SERIAL PRIMARY KEY,
  community_id    VARCHAR(32) NOT NULL,
  title           VARCHAR(200) NOT NULL,
  summary         VARCHAR(500) DEFAULT '',
  content         TEXT DEFAULT '',
  author_phone    VARCHAR(20) NOT NULL,
  author_name     VARCHAR(80) NOT NULL DEFAULT '',
  image_url       VARCHAR(512) DEFAULT NULL,
  likes_count     INT NOT NULL DEFAULT 0,
  comments_count  INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (community_id) REFERENCES communities(id)
);

CREATE INDEX IF NOT EXISTS idx_topics_community ON topics(community_id);
CREATE INDEX IF NOT EXISTS idx_topics_created ON topics(created_at);
