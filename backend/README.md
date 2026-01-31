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
| GET | `/growth` | 成长页整页数据（需登录）：提醒、统计、每日任务、今日学习、双卡；reminder/stats 来自用户设置与统计，growthCards 由 stats 计算 |
| PATCH | `/growth/reminder` | 更新每日提醒设置（body: `{ "reminderTime": "20:00", "message": "可选文案" }`，需登录） |
| PATCH | `/growth/stats` | 更新成长统计（body: `{ "streakDays", "accuracyPercent", "badgeCount", "weeklyDone", "weeklyTotal" }` 均可选，需登录） |
| PATCH | `/growth/daily-tasks` | 更新某项每日任务完成状态（body: `{ "taskId": "school", "completed": true }`，需登录） |
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

成长页接口详细设计见 [docs/growth-api.md](docs/growth-api.md)。

## 目录结构

```
backend/
├── package.json
├── .env.example
├── README.md
├── docs/
│   └── growth-api.md    # 成长页接口设计
├── sql/
│   ├── 001_schema.sql   # 认证/用户表
│   └── 002_growth_schema.sql   # 成长页表（可选，当前用内存）
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
        ├── growth.js
        └── chat.js
```

## 与 starknow-ai-proxy 的关系

- **starknow-ai-proxy**：原 AI 代理服务，端口 3001，认证/用户为内存存储。
- **backend（本仓库）**：独立后端工程，端口 3002，认证/用户使用 PostgreSQL，接口与 App 完全兼容（含 `/chat` 与 `/duel`）。

App 只需配置一个 baseUrl：使用本后端时填 `http://localhost:3002`，使用原代理时填 `http://localhost:3001`。
