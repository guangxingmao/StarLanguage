-- 单人挑战记录：仅在做完所有题目后提交时写入，供「我的排名」- 最近挑战 展示与详情
-- 执行顺序：005_arena_schema 之后。依赖：users 表

CREATE TABLE IF NOT EXISTS arena_challenge_sessions (
  id              SERIAL PRIMARY KEY,
  phone           VARCHAR(20) NOT NULL,
  topic           VARCHAR(64) NOT NULL DEFAULT '全部',
  subtopic        VARCHAR(64) NOT NULL DEFAULT '全部',
  total_questions INT NOT NULL DEFAULT 0,
  correct_count   INT NOT NULL DEFAULT 0,
  score           INT NOT NULL DEFAULT 0,
  answers         JSONB NOT NULL DEFAULT '[]',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- answers 每项: { questionId, title, userChoice, correctAnswer, isCorrect }
CREATE INDEX IF NOT EXISTS idx_arena_challenge_sessions_phone ON arena_challenge_sessions(phone);
CREATE INDEX IF NOT EXISTS idx_arena_challenge_sessions_created ON arena_challenge_sessions(created_at DESC);
