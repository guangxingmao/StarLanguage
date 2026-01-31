-- 星知后端数据库表结构（与 server.js 内存结构对应，供后续接入使用）
-- 数据库 starknow 与下表由 Docker 首次启动时自动创建（见 docker-compose 中 db 的 docker-entrypoint-initdb.d）。
-- 若需手动建表：在 DBeaver 中连接到 starknow 后执行本脚本即可。

-- 验证码（对应 server.js 的 codes Map）
CREATE TABLE IF NOT EXISTS auth_codes (
  phone       VARCHAR(20) PRIMARY KEY,
  code        VARCHAR(10) NOT NULL,
  expires_at  BIGINT NOT NULL
);

-- 登录令牌（对应 server.js 的 tokens Map）
CREATE TABLE IF NOT EXISTS auth_tokens (
  token       VARCHAR(64) PRIMARY KEY,
  phone       VARCHAR(20) NOT NULL,
  created_at  BIGINT NOT NULL
);

-- 用户资料（对应 server.js 的 users Map）
CREATE TABLE IF NOT EXISTS users (
  phone          VARCHAR(20) PRIMARY KEY,
  phone_number   VARCHAR(20) NOT NULL,
  name           VARCHAR(100) NOT NULL DEFAULT '',
  avatar_index   INT NOT NULL DEFAULT 0,
  avatar_base64  TEXT,
  created_at     BIGINT,
  updated_at     BIGINT
);

-- 可选：建索引便于按 phone 查 token、按过期时间清理
CREATE INDEX IF NOT EXISTS idx_auth_tokens_phone ON auth_tokens(phone);
CREATE INDEX IF NOT EXISTS idx_auth_codes_expires ON auth_codes(expires_at);
