## ADDED Requirements

### Requirement: 安全约束
系统 SHALL 禁止在客户端存储/暴露密钥，密钥仅存在于本地代理进程内存中。

#### Scenario: 密钥输入
- **WHEN** 代理启动
- **THEN** 通过交互式输入密钥，不落盘
