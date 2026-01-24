# 数据与内容模型

## MODIFIED Requirements

### Requirement: Demo 数据模型
系统 SHALL 使用本地 JSON 文件描述主题、内容、题库、成就与排行数据。

#### Scenario: 数据加载
- **WHEN** 应用启动
- **THEN** 系统从本地 JSON 加载主题、内容、题库、成就与排行数据

### Requirement: 知识结构
系统 SHALL 以“主题 → 子主题 → 知识点”结构承载内容与题库。

#### Scenario: 题库结构
- **WHEN** 题库加载
- **THEN** 每道题包含主题与子主题字段用于筛选与排行
