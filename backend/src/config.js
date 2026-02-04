const path = require('path');
// 先加载项目根目录 .env，再加载 backend/.env（backend/.env 优先，便于本地用 3002 与 Docker 的 3001 区分）
require('dotenv').config({ path: path.resolve(process.cwd(), '..', '.env') });
require('dotenv').config();

// 默认 3002：与 Docker 的 app(3001) 区分，本地跑 backend 时不易 EADDRINUSE
module.exports = {
  port: process.env.PORT ? Number(process.env.PORT) : 3002,
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'postgres://starknow:starknow@localhost:5433/starknow',
  tencent: {
    secretId: process.env.TENCENT_SECRET_ID,
    secretKey: process.env.TENCENT_SECRET_KEY,
    region: process.env.TENCENT_REGION || 'ap-guangzhou',
  },
  auth: {
    codeTtlMs: 5 * 60 * 1000,
  },
};
