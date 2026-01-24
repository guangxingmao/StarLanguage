# Change: 接入腾讯混元（本地代理）

## Why
为 AI 助手提供真实可用的对话能力，并确保密钥不暴露在 Flutter/Web 端。

## What Changes
- 新增本地代理服务（本机运行），由代理调用腾讯混元 ChatCompletions 接口
- Flutter 端改为调用本地代理地址（用户可配置 IP/端口）
- 增加安全约束：密钥仅在本地代理进程中输入，不落盘、不进入仓库

## Impact
- Affected specs: assistant, app, data
- Affected code: 新增本地代理项目；Flutter AI 助手调用逻辑与设置入口
