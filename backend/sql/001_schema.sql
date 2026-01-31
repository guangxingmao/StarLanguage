-- 星知后端数据库表结构（与 App 接口对应）
-- 与项目根 docker-compose 中 db 的 init 脚本一致，可共用同一库 starknow。

CREATE TABLE IF NOT EXISTS auth_codes (
  phone       VARCHAR(20) PRIMARY KEY,
  code        VARCHAR(10) NOT NULL,
  expires_at  BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_tokens (
  token       VARCHAR(64) PRIMARY KEY,
  phone       VARCHAR(20) NOT NULL,
  created_at  BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  phone          VARCHAR(20) PRIMARY KEY,
  phone_number   VARCHAR(20) NOT NULL,
  name           VARCHAR(100) NOT NULL DEFAULT '',
  avatar_index   INT NOT NULL DEFAULT 0,
  avatar_base64  TEXT,
  created_at     BIGINT,
  updated_at     BIGINT
);

CREATE INDEX IF NOT EXISTS idx_auth_tokens_phone ON auth_tokens(phone);
CREATE INDEX IF NOT EXISTS idx_auth_codes_expires ON auth_codes(expires_at);
