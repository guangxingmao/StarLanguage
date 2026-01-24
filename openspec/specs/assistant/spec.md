# AI 助手规范

## MODIFIED Requirements

### Requirement: 对话式入口
系统 SHALL 提供 AI 助手的聊天式界面，支持输入文本与图片。

#### Scenario: 文本问答
- **WHEN** 用户发送文本问题
- **THEN** 系统在聊天记录中展示消息与回复

#### Scenario: 图片识别
- **WHEN** 用户选择图片上传
- **THEN** 系统在聊天记录中展示“图片消息”占位

### Requirement: 识图输出（Demo）
系统 SHALL 在 Demo 中以固定示例展示识别结果与知识点。

#### Scenario: 输出结构
- **WHEN** 用户发送图片
- **THEN** 系统展示识别结果 + 1-3 条知识点 + 1 条追问

### Requirement: 历史记录
系统 SHALL 在助手页面展示历史对话记录。

#### Scenario: 进入助手页面
- **WHEN** 用户进入 AI 助手
- **THEN** 系统显示历史消息列表
