# 学习流规范

## MODIFIED Requirements

### Requirement: 搜索与筛选
系统 SHALL 提供学习流的搜索框与筛选能力（类型、来源、主题）。

#### Scenario: 搜索过滤
- **WHEN** 用户输入关键词或回车提交
- **THEN** 列表仅展示标题/摘要/标签/主题/来源匹配的内容

#### Scenario: 主题筛选
- **WHEN** 用户选择主题筛选
- **THEN** 学习流仅展示对应主题的内容卡片

### Requirement: 内容卡片与外链跳转
系统 SHALL 以卡片化瀑布流展示内容，并支持外链跳转。

#### Scenario: 点击跳转
- **WHEN** 用户点击内容卡片
- **THEN** 系统打开外部链接（浏览器或应用）

### Requirement: 素材展示
系统 SHALL 为每条内容展示封面插画、标题、摘要、来源与类型标识。

#### Scenario: 封面显示
- **WHEN** 学习流加载内容
- **THEN** 每张卡片渲染本地插画封面并展示标题摘要

### Requirement: 内容策略（Demo）
系统 SHALL 使用自建内容卡片作为 Demo 数据，视频仅以外链形式提供。

#### Scenario: 内容来源
- **WHEN** 内容为视频类型
- **THEN** 系统仅提供外链跳转，不直接分发第三方视频内容

### Requirement: 轻量知识结构
系统 SHALL 采用轻量“主题 → 子主题 → 知识点”结构承载学习内容。

#### Scenario: 主题结构
- **WHEN** 内容载入
- **THEN** 每条内容归属于主题与子主题层级
