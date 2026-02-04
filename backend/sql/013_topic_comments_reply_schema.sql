-- 评论支持二级回复：parent_id 为空为一级评论，非空为回复某条评论
-- 执行顺序：012_topic_likes_comments_schema → 本脚本

ALTER TABLE topic_comments
  ADD COLUMN IF NOT EXISTS parent_id INT NULL REFERENCES topic_comments(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS reply_to_author VARCHAR(80) DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_topic_comments_parent ON topic_comments(parent_id);

COMMENT ON COLUMN topic_comments.parent_id IS '为空则一级评论，非空则为回复该 id 的评论';
COMMENT ON COLUMN topic_comments.reply_to_author IS '回复对象的昵称，用于展示「回复 xxx」';
