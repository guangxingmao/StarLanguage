-- 局域网对战记录：每场对战双方各提交一条，记录对手与双方得分，供「我的排名」- 最近挑战 展示及判定胜负
-- 执行顺序：005_arena_schema、users 表之后

CREATE TABLE IF NOT EXISTS arena_lan_duel_sessions (
  id              SERIAL PRIMARY KEY,
  user_phone      VARCHAR(20) NOT NULL,
  opponent_phone  VARCHAR(20) NOT NULL,
  user_score      INT NOT NULL DEFAULT 0,
  opponent_score  INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_arena_lan_duel_user ON arena_lan_duel_sessions(user_phone);
CREATE INDEX IF NOT EXISTS idx_arena_lan_duel_created ON arena_lan_duel_sessions(created_at DESC);

COMMENT ON TABLE arena_lan_duel_sessions IS '局域网对战记录：user_phone 为当前用户，opponent_phone 为对手，用于最近挑战与胜负判定';
