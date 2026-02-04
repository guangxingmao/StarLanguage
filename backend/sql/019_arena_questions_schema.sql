-- 知识擂台题库表（与 Flutter Question 结构一致）
-- 依赖：无，在 starknow 库中执行

CREATE TABLE IF NOT EXISTS arena_questions (
  id          VARCHAR(32) PRIMARY KEY,
  topic       VARCHAR(64) NOT NULL,
  subtopic    VARCHAR(64) NOT NULL DEFAULT '综合知识',
  title       TEXT NOT NULL,
  options     JSONB NOT NULL,
  answer      VARCHAR(2) NOT NULL,
  created_at  BIGINT
);

COMMENT ON TABLE arena_questions IS '知识擂台题目：options 为 ["A. xxx", "B. xxx", ...]，answer 为 A/B/C/D';
CREATE INDEX IF NOT EXISTS idx_arena_questions_topic ON arena_questions(topic);
