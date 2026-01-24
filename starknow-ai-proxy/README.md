# StarKnow AI Proxy

本地代理服务，用于转发 Flutter AI 助手请求到腾讯混元 ChatCompletions 接口。

## 运行

```bash
npm install
npm start
```

启动后按提示输入 `SecretId` 与 `SecretKey`（不会落盘）。

默认端口：`3001`，可通过 `PORT` 设置。

## 环境变量（可选）

```bash
export TENCENT_SECRET_ID=xxxx
export TENCENT_SECRET_KEY=xxxx
export TENCENT_REGION=ap-guangzhou
export PORT=3001
```

## API

- `GET /health`
- `POST /chat`
- `WS /duel`（局域网中继对战）

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
