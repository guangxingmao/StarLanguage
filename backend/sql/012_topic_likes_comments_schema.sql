-- 话题点赞与评论表（需先有 topics 表）
-- 在 starknow 库中执行

-- 点赞记录：每个用户对每个话题最多一条
CREATE TABLE IF NOT EXISTS topic_likes (
  topic_id   INT NOT NULL,
  user_phone VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (topic_id, user_phone),
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_topic_likes_topic ON topic_likes(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_likes_user ON topic_likes(user_phone);

-- 评论表
CREATE TABLE IF NOT EXISTS topic_comments (
  id           SERIAL PRIMARY KEY,
  topic_id     INT NOT NULL,
  author_phone VARCHAR(20) NOT NULL,
  author_name  VARCHAR(80) NOT NULL DEFAULT '',
  content      TEXT NOT NULL DEFAULT '',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_topic_comments_topic ON topic_comments(topic_id);
