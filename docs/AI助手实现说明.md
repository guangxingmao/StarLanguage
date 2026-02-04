# AI 助手功能实现说明

## 一、现状概览

项目里 **AI 助手已实现**，包含：

| 部分 | 位置 | 作用 |
|------|------|------|
| **前端入口** | 底部导航中间的「光球」 | 点击进入 AI 助手页 |
| **聊天页** | `lib/main.dart` → `AssistantPage` | 文本对话 + 识图，调用代理接口 |
| **请求封装** | `lib/main.dart` → `AiProxyClient` | 封装 `/chat` 的文本、识图请求 |
| **代理地址** | `lib/data/ai_proxy.dart` → `AiProxyStore` | 可配置后端 baseUrl（默认 `http://localhost:3001`，与 API 同端口） |
| **后端接口** | `backend/src/routes/chat.js` | `POST /chat`，对接腾讯云混元（文本 + 识图） |

流程简要：

- 用户在助手页输入文字或上传图片 → Flutter 调 `AiProxyClient.request` / `requestImage`，请求 `AiProxyStore.url + /chat`。
- 后端收到请求后调用腾讯云混元（Hunyuan），把 `reply` 返回给前端展示。

---

## 二、单服务、单端口（推荐）

**只需起一个 Node 服务**：`backend/` 已包含 **全部接口**（认证、用户、圈子、话题、成长、擂台等）和 **AI 对话**（`POST /chat`）。无需再跑 `starknow-ai-proxy`。

- 默认端口：**3001**（可在 `.env` 里改 `PORT`）
- App 默认请求：`http://localhost:3001`（API 与 AI 共用该地址）

## 三、如何跑通

### 1. 后端（唯一需要起的服务）

- 在**项目根目录**或 `backend/` 下配置 `.env`（可参考 `.env.example`）：
  - **PORT**：默认 `3001`，可不写或写 `3001`。
  - **TENCENT_SECRET_ID / TENCENT_SECRET_KEY**：腾讯云控制台创建并填入，用于混元 API。
  - **TENCENT_REGION**：可选，默认 `ap-guangzhou`。
  - **DATABASE_URL**：数据库连接串（本地开发可用 `postgres://starknow:starknow@localhost:5433/starknow`）。
- 启动方式（在 `backend` 目录）：
  ```bash
  cd backend && npm install && node src/index.js
  ```
- 若未配置腾讯云密钥，后端会正常起但 AI 不可用，接口会返回 503 和「未配置腾讯云密钥」的提示。

### 2. 前端

- `AiProxyStore.url` 默认已是 `http://localhost:3001`，与单服务一致，一般无需改。
- 真机调试时改为电脑局域网 IP，例如 `http://192.168.x.x:3001`。

### 3. 接口约定（前后端对齐）

- **文本对话**：`POST /chat`，body：
  - `messages`: `[{ role: 'user'|'assistant'|'system', content: string }]`
  - 可选：`model`, `temperature`, `topP`, `stream: false`
- **识图**：同一 `POST /chat`，body：
  - `imageBase64`: 图片 base64
  - `imageMime`: 如 `image/jpeg`
  - `question`: 对图片的提问
- 响应：`{ reply: string, model?, usage?, raw? }`，前端用 `reply` 展示。

---

## 三、可选增强方向

若要在现有「能对话、能识图」的基础上继续增强，可考虑：

1. **流式输出（stream）**  
   后端 `chat.js` 当前返回整段 `reply`；可改为混元流式接口，前端用 SSE 或 WebSocket 逐段渲染，提升体验。

2. **登录态**  
   若希望按用户隔离或限流，可在 `POST /chat` 上增加鉴权（如校验 `Authorization`），从 token 取用户 id，再决定是否调用混元、是否写库。

3. **历史记录持久化**  
   当前对话只在内存中；可把会话存库（用户 id + 会话 id + 消息列表），并增加「历史会话列表」入口，便于续聊。

4. **系统提示词可配置**  
   目前前端 `_buildMessages` 里写死「面向儿童的科普助手」；可改为从后端或配置下发，方便运营调整人设。

5. **错误与重试**  
   前端对 `AiProxyClient` 返回的 `null` 已展示「暂时无法连接…」；可区分 503（未配置密钥）、5xx（超时/限流）做不同提示或重试。

6. **UI/交互**  
   助手页可增加：打字机效果、复制回复、清空会话、主题色与 App 统一等（与现有 `AssistantPage` 的布局和 `_ChatMessage` 结合即可）。

---

## 四、常见错误

### 「服务未开通」FailedOperation.ServiceNotActivated

- **现象**：后端日志出现 `[chat] TencentCloudSDKHttpException ... code: 'FailedOperation.ServiceNotActivated'`，或接口返回 503、`service_not_activated`。
- **原因**：当前腾讯云账号下 **混元（Hunyuan）大模型服务尚未开通**。密钥（TENCENT_SECRET_ID / TENCENT_SECRET_KEY）有效，但产品未开通。
- **处理**：
  1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/)。
  2. 搜索并进入「**混元**」或「**Hunyuan**」产品页。
  3. 按页面提示 **开通服务**（可能涉及实名、计费方式等）。
  4. 开通后再调用 `/chat` 即可。

若暂时不需要 AI 对话，可不开通；后端其它接口（认证、用户、圈子等）不受影响，仅助手页对话会报错。

---

## 五、小结

- **要能用起来**：配置腾讯云混元密钥 → 启动后端 → 前端代理地址指到后端（端口一致）→ 在助手页发文字或发图即可。
- **要「实现」更多**：在现有 `/chat` + `AssistantPage` + `AiProxyClient` 基础上，按上面增强方向选做流式、鉴权、历史、提示词、错误处理和 UI 即可。

如你接下来想做的是其中某一项（例如只做流式或只做历史记录），可以说明一下，我可以按那一项给出更具体的改法（含建议的文件和代码位置）。
