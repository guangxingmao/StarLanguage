-- 在线 PK 排行与个人积分排行分离：PK 排行用 pk_score（局域网对战），个人积分用 total_score（单人挑战）
-- 执行顺序：005_arena_schema 之后

ALTER TABLE user_arena_stats
  ADD COLUMN IF NOT EXISTS pk_score INT NOT NULL DEFAULT 0;

COMMENT ON COLUMN user_arena_stats.pk_score IS '局域网 PK 累计得分，用于在线 PK 排行';
