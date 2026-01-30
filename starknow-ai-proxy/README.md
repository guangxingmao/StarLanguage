# StarKnow AI Proxy

本地代理服务：转发 Flutter AI 助手请求到腾讯混元；提供认证与用户接口（手机号 + 6 位验证码）。

**不需要 Docker**：直接在本机用 Node 运行即可。Docker 可在以后需要数据库或生产部署时再使用。

## 运行

```bash
cd starknow-ai-proxy
npm install
npm start
```

- 未设置腾讯云密钥时，仅启动认证与用户 API（AI 对话不可用）。
- 设置环境变量后无需输入，启动后可直接使用 `/chat`。

默认端口：`3001`，可通过 `PORT` 设置。

## 环境变量（可选）

```bash
export TENCENT_SECRET_ID=xxxx
export TENCENT_SECRET_KEY=xxxx
export TENCENT_REGION=ap-guangzhou
export PORT=3001
```

## API

### 健康检查
- `GET /health` — 返回 `{ ok, service, aiEnabled }`

### 认证（Demo：验证码存内存，不真实发短信）
- `POST /auth/send-code` — 请求体 `{ "phone": "13800138000" }`，返回 `{ "ok": true, "demoCode": "123456" }`
- `POST /auth/verify` — 请求体 `{ "phone": "13800138000", "code": "123456" }`，返回 `{ "ok": true, "token": "...", "user": { ... } }`

### 用户（需 Header：`Authorization: Bearer <token>`）
- `GET /user/me` — 当前用户信息
- `PATCH /user/me` — 更新昵称/头像等，请求体 `{ "name", "avatarIndex", "avatarBase64" }` 等

### AI 与对战
- `POST /chat` — 对话（需配置腾讯云密钥）
- `WS /duel` — 局域网中继对战

中继对战消息示例：

```json
{"type":"host","room":"1234"}
```

```json
{"type":"join","room":"1234","name":"星知玩家"}
```

请求体示例：

```json
{
  "model": "hunyuan-turbos-latest",
  "messages": [
    {"role": "system", "content": "你是儿童科普助手"},
    {"role": "user", "content": "为什么天空是蓝色的？"}
  ],
  "temperature": 0.6,
  "topP": 1.0,
  "stream": false
}
```
