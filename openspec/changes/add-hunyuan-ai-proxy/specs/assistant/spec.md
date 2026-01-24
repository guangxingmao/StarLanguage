## ADDED Requirements

### Requirement: 本地代理接入
系统 SHALL 通过本地代理转发 AI 请求，避免 Flutter/Web 端持有密钥。

#### Scenario: 代理请求
- **WHEN** 用户在 AI 助手中发送消息
- **THEN** 系统调用本地代理并返回模型回复

### Requirement: 代理地址配置
系统 SHALL 提供本地代理地址配置入口（IP/端口）。

#### Scenario: 设置代理
- **WHEN** 用户输入代理地址
- **THEN** 系统保存该地址并用于后续 AI 请求

### Requirement: 图片识别（多模态）
系统 SHALL 支持发送图片给本地代理进行多模态识别并返回结果。

#### Scenario: 发送图片
- **WHEN** 用户在 AI 助手上传图片
- **THEN** 系统将图片与提示词发送至代理
- **AND** 系统展示模型返回的识别与科普说明
