## ADDED Requirements

### Requirement: AI 请求模型
系统 SHALL 以 ChatCompletions 请求格式与代理交互，并支持非流式响应。

#### Scenario: 非流式响应
- **WHEN** 代理返回模型结果
- **THEN** 系统将回复写入对话记录
