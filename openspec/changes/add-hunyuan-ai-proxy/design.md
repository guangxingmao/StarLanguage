# Design: 本地代理接入腾讯混元

## 目标
- Flutter/Web 端不直接持有密钥
- 代理可本机运行，便于演示

## 架构
```
Flutter(Web) -> 本地代理(HTTP) -> 腾讯混元 ChatCompletions API
```

## 关键点
- 代理启动时交互式输入 SecretId/SecretKey
- 代理仅持有内存态密钥，不落盘
- 默认端口：3001（可配置）
- Flutter 端通过设置页填写代理地址（http://localhost:3001）

## API 选择
- 使用 ChatCompletions 接口（Hunyuan 2023-09-01 版本）
- 非流式为主，预留 SSE 流式转发能力
