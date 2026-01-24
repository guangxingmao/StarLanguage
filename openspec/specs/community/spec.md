# 社群规范

## MODIFIED Requirements

### Requirement: 已加入社群
系统 SHALL 展示用户已加入的社群标签列表。

#### Scenario: 社群展示
- **WHEN** 用户进入社群页
- **THEN** 系统展示已加入的社群标签

### Requirement: 今日话题与瀑布流
系统 SHALL 展示今日热门话题与瀑布流帖子。

#### Scenario: 浏览帖子
- **WHEN** 用户滑动社群页
- **THEN** 系统展示帖子卡片（头像、标题、内容摘要）

### Requirement: 圈子主页
系统 SHALL 支持点击圈子进入圈子主页，并展示该圈子的话题列表。

#### Scenario: 进入圈子
- **WHEN** 用户点击已加入的圈子
- **THEN** 系统进入圈子主页并显示圈子话题

### Requirement: 话题详情
系统 SHALL 支持点击热门话题进入话题详情页。

#### Scenario: 进入话题
- **WHEN** 用户点击话题卡片
- **THEN** 系统进入话题详情并展示内容

### Requirement: 评论列表与发布
系统 SHALL 在话题详情页展示评论列表并支持发布评论。

#### Scenario: 发布评论
- **WHEN** 用户在话题详情页提交评论
- **THEN** 系统将评论加入该话题的评论列表

### Requirement: 发布话题
系统 SHALL 提供发布话题入口，并要求选择圈子标签。

#### Scenario: 发布新话题
- **WHEN** 用户在圈子或社群页点击发布
- **THEN** 系统打开编辑页并在提交时绑定圈子标签

### Requirement: 话题图片
系统 SHALL 支持为新话题添加图片并在话题卡片/详情页展示。

#### Scenario: 添加图片
- **WHEN** 用户在发布话题时选择图片
- **THEN** 话题发布后在卡片与详情页显示图片

### Requirement: 轻量互动入口（Demo）
系统 SHALL 提供轻量互动入口（评论/发布占位）。

#### Scenario: 帖子互动
- **WHEN** 用户点击帖子
- **THEN** 系统展示评论入口与互动占位内容

### Requirement: 加入社群入口
系统 SHALL 提供“加入新社群”的入口按钮。

#### Scenario: 点击加入
- **WHEN** 用户点击右上角“+”
- **THEN** 系统弹出加入社群的引导入口
