# 应用总览与信息架构

## MODIFIED Requirements

### Requirement: 信息架构
系统 SHALL 提供五大主入口：学习、社群、AI 助手、擂台、成长（我的）。

#### Scenario: 主导航
- **WHEN** 用户进入应用
- **THEN** 系统显示底部导航，包含学习/社群/AI/擂台/成长

### Requirement: 核心体验闭环
系统 SHALL 支持“看内容 → 学知识 → 做题 → 得成长/成就”的体验闭环。

#### Scenario: 体验闭环
- **WHEN** 用户完成学习与答题
- **THEN** 系统在成长页与成就墙中反映学习成果

### Requirement: 用户故事（Demo）
系统 SHALL 满足以下核心用户故事（演示范围）。

#### Scenario: 浏览内容
- **WHEN** 孩子浏览趣味内容卡片
- **THEN** 可点击外链打开视频或图文

#### Scenario: 识图问答
- **WHEN** 孩子在 AI 助手上传图片
- **THEN** 可看到识别结果与知识点

#### Scenario: 参与擂台
- **WHEN** 孩子完成 10 题限时挑战
- **THEN** 系统展示得分与称号
