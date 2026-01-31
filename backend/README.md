# 星知后端（starknow-backend）

为星知 Flutter App 提供 REST 与 WebSocket 接口：认证、用户资料、AI 对话、擂台中继。使用 **Node.js + Express**，数据存 **PostgreSQL**。

## 接口一览（与 App 对应）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查 |
| POST | `/auth/send-code` | 发送验证码（body: `{ phone }`） |
| POST | `/auth/verify` | 验证码登录（body: `{ phone, code }`） |
| GET | `/user/me` | 获取当前用户（Header: `Authorization: Bearer <token>`） |
| PATCH | `/user/me` | 更新当前用户（body: `name` / `avatarIndex` / `avatarBase64` / `phoneNumber`） |
| POST | `/chat` | AI 对话（同 starknow-ai-proxy，需腾讯云密钥） |
| WebSocket | `/duel` | 擂台中继（建房间 / 加入 / 消息转发） |

认证与用户数据使用 PostgreSQL（表结构见 `sql/001_schema.sql`），可与项目根目录的 `docker-compose` 共用同一数据库。

## 本地运行

### 1. 安装依赖

```bash
cd backend
npm install
```

### 2. 环境变量

```bash
cp .env.example .env
# 编辑 .env，至少填写 DATABASE_URL（若本地用 docker-compose 起的 db，可用 postgres://starknow:starknow@localhost:5433/starknow）
# 需要 AI 对话时填写 TENCENT_SECRET_ID、TENCENT_SECRET_KEY
```

### 3. 数据库

确保 PostgreSQL 已启动且已建表（项目根目录执行 `docker compose up -d` 后，db 会自动建库和表）。若单独建表，在 `starknow` 库中执行 `sql/001_schema.sql`。

### 4. 启动

```bash
npm start
# 或开发时自动重启
npm run dev
```

默认监听 **3002**（与 starknow-ai-proxy 的 3001 区分）。  
在 App 内将「服务地址」设为 `http://localhost:3002` 即可连到本后端。

## 目录结构

```
backend/
├── package.json
├── .env.example
├── README.md
├── sql/
│   └── 001_schema.sql   # 建表脚本
└── src/
    ├── index.js         # 入口、Express、WebSocket
    ├── config.js        # 环境变量
    ├── db.js            # pg 连接池
    ├── middleware/
    │   └── auth.js      # Bearer 校验
    └── routes/
        ├── health.js
        ├── auth.js
        ├── user.js
        └── chat.js
```

## 与 starknow-ai-proxy 的关系

- **starknow-ai-proxy**：原 AI 代理服务，端口 3001，认证/用户为内存存储。
- **backend（本仓库）**：独立后端工程，端口 3002，认证/用户使用 PostgreSQL，接口与 App 完全兼容（含 `/chat` 与 `/duel`）。

App 只需配置一个 baseUrl：使用本后端时填 `http://localhost:3002`，使用原代理时填 `http://localhost:3001`。
