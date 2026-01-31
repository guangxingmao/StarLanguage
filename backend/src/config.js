require('dotenv').config();

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
