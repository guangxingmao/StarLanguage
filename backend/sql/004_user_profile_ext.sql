-- 个人主页扩展字段：在 users 表上增加等级、基础信息、隐私等（与个人页 UI 对应）
-- 执行顺序：在 001_schema、002、003 之后执行；首次 Docker 启动会按文件名顺序自动执行。
-- 已有库可单独执行本脚本以添加列（PostgreSQL 11+ 支持 ADD COLUMN IF NOT EXISTS）。

ALTER TABLE users ADD COLUMN IF NOT EXISTS age VARCHAR(20) DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS interests VARCHAR(300) DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS level INT NOT NULL DEFAULT 1;
ALTER TABLE users ADD COLUMN IF NOT EXISTS level_title VARCHAR(50) DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS level_exp INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy VARCHAR(20) DEFAULT 'default';

-- 说明：
-- age: 年龄展示，如 '9' 或 '9 岁'
-- interests: 兴趣，如 '篮球 / 科学'
-- level: 等级数字，如 1、2、3
-- level_title: 等级称号，如 '星光探索者'
-- level_exp: 当前等级经验/进度数值，用于进度条（如 62 表示 62%）
-- privacy: 隐私设置，如 'default' / '默认'
