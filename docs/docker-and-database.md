# Docker 与数据库接入说明

当前 **未修改 server.js**，仅增加 Docker 与数据库环境，便于后续在服务里接入数据库。

---

## 从零开始使用（Docker 客户端已安装）

### 步骤 1：确保 Docker 在运行

- 打开 **Docker Desktop**（菜单栏有鲸鱼图标即表示在运行）。
- 终端执行 `docker info`，无报错即表示可用。

### 步骤 2：配置环境变量

在**项目根目录**（有 `docker-compose.yml` 的目录）执行：

```bash
cp .env.example .env
```

用编辑器打开 `.env`：
- **要用 AI 对话/识图**：填写腾讯云密钥 `TENCENT_SECRET_ID`、`TENCENT_SECRET_KEY`。
- **仅跑数据库、暂不用 AI**：可保留这两项为空（或删掉等号后的内容），避免 `docker compose` 报 `The "TENCENT_SECRET_ID" variable is not set` 的 WARN。

数据库相关可先不改，默认即可：用户/密码/库名均为 `starknow`。

### 步骤 3：启动应用和数据库

仍在项目根目录执行：

```bash
docker compose up -d
```

首次会拉取 PostgreSQL 镜像并构建 Node 镜像，可能需要一两分钟。完成后会启动两个容器：

- **app**（starknow-ai-proxy）：AI 代理，端口 3001
- **db**（PostgreSQL）：数据库，端口 5433（宿主机映射，避免与本机 5432 冲突）

**数据库和表**：首次执行 `docker compose up -d` 时（或执行 `docker compose down -v` 后再次 `up -d`，数据目录为空时），PostgreSQL 会按文件名顺序执行 `docker-entrypoint-initdb.d/` 下的脚本：`001_schema.sql`（认证/用户表）、`002_growth_schema.sql`（成长页表）、`002_seed_user.sql`（默认演示用户）、`003_growth_seed.sql`（成长页初始数据）。因此**全新启动**后库中会有一条演示用户及其成长页数据。  
若你**之前已经启动过 db**（数据卷非空），这些 init 脚本**不会再次执行**，表里可能没有成长页数据。此时可二选一：  
- **清空后重新初始化**：`docker compose down -v` 再 `docker compose up -d`（会清空数据库并重新跑所有 init 脚本）；  
- **不删数据，手动补数据**：在 DBeaver 里对库 `starknow` 依次执行 `backend/sql/002_growth_schema.sql`、`backend/sql/002_seed_user.sql`、`backend/sql/003_growth_seed.sql`。

### 步骤 4：验证是否正常

```bash
# 看容器是否都在运行
docker compose ps

# 看 app 日志（确认无报错）
docker compose logs app
```

- 浏览器或 Flutter 里访问 **http://localhost:3001**，能通即表示 AI 代理正常。
- 数据库：见下文「如何连接数据库」。

### 步骤 5：日常使用

| 操作 | 命令 |
|------|------|
| 启动 | `docker compose up -d` |
| 停止 | `docker compose down` |
| 看 app 日志 | `docker compose logs -f app` |
| 看 db 日志 | `docker compose logs -f db` |
| 只重启 app | `docker compose up -d --build app` |

`docker compose down` 只会删容器，**数据库数据**在 volume 里会保留，下次 `up -d` 数据仍在。

**常见提示：**
- **`The "TENCENT_SECRET_ID" variable is not set`**：未配置 `.env` 或未写 `TENCENT_SECRET_ID`/`TENCENT_SECRET_KEY`。复制 `.env.example` 为 `.env` 并至少保留这两项（可为空），WARN 即消失。
- **`The input device is not a TTY`**：在非交互环境（如 IDE 终端、脚本）里执行 `docker compose run`/`exec` 时可能出现，一般可忽略；若需去掉提示，可加 `-T`，例如：`docker compose run -T app node -e "console.log(1)"`。

---

## 如何连接数据库（PostgreSQL）

- **主机**：`localhost`（本机）或 `db`（在 Docker 网络内，仅其他容器用）
- **端口**：`5433`（或 `.env` 里 `POSTGRES_PORT`，默认 5433）
- **用户**：`starknow`（或 `.env` 里 `POSTGRES_USER`）
- **密码**：`starknow`（或 `.env` 里 `POSTGRES_PASSWORD`）
- **数据库名**：`starknow`（或 `.env` 里 `POSTGRES_DB`）

**命令行连接（本机）：**

```bash
# 用 Docker 自带的 psql 连到 db 容器
docker compose exec db psql -U starknow -d starknow -c "SELECT 1;"
```

**图形化客户端（本机）：**

- 用 DBeaver、TablePlus、Navicat 等，新建 PostgreSQL 连接：
  - Host: `localhost`
  - Port: `5433`
  - User: `starknow`
  - Password: `starknow`
  - Database: `starknow`

**连接串（给 server 或代码用）：**

- 在**本机**跑 Node 连 Docker 里的数据库：  
  `postgres://starknow:starknow@localhost:5433/starknow`
- 在 **Docker 内**（如 app 容器）连 db：  
  `postgres://starknow:starknow@db:5432/starknow`  
  （docker-compose 已通过 `DATABASE_URL` 注入给 app，后续改 server 时可直接用 `process.env.DATABASE_URL`。）

---

## 数据库连接不上时排查

按下面顺序检查，多数情况是 **db 容器没启动** 或 **端口/主机填错**。

### 1. 确认 db 容器在运行

在项目根目录执行：

```bash
docker compose ps
```

应看到两个容器：**app**（starknow-ai-proxy）和 **db**（starknow-db），状态均为 `Up`。  
若只有 app、没有 db，说明数据库容器未启动，执行：

```bash
docker compose up -d
```

会同时启动 app 和 db。若 db 启动失败，看日志：

```bash
docker compose logs db
```

根据报错排查（常见：端口被占用、数据卷权限、init 脚本报错）。

### 2. 本机连接参数（DBeaver / TablePlus / 命令行）

从**本机**连 Docker 里的 PostgreSQL，必须用「宿主机端口」：

| 项     | 值        | 说明 |
|--------|-----------|------|
| Host   | `localhost` 或 `127.0.0.1` | 不要填 `db`（`db` 是容器名，只在 Docker 网络内有效） |
| Port   | **5433**  | 宿主机映射端口（与 `.env` 里 `POSTGRES_PORT` 一致，默认 5433） |
| User   | `starknow` | 与 `.env` 里 `POSTGRES_USER` 一致 |
| Password | `starknow` | 与 `.env` 里 `POSTGRES_PASSWORD` 一致 |
| Database | `starknow` | 与 `.env` 里 `POSTGRES_DB` 一致 |

**常见错误**：端口填成 `5432`。容器内部是 5432，但宿主机映射的是 5433，本机客户端必须连 **5433**。

### 3. 用命令行快速验证

在项目根目录执行：

```bash
docker compose exec db psql -U starknow -d starknow -c "SELECT 1;"
```

若输出 `?column?` 和 `1`，说明数据库正常，问题多半在客户端的主机/端口配置。

### 4. 若本机已安装 PostgreSQL（占用 5432）

项目已用 5433 映射，不会冲突。只要客户端连 **localhost:5433** 即可，不要连 5432。

### 5. backend 或其它本地服务连库

本地跑的 Node（如 `backend`）要连 Docker 里的库时，连接串用：

```
postgres://starknow:starknow@localhost:5433/starknow
```

可在项目根或 `backend` 目录的 `.env` 里设置 `DATABASE_URL=postgres://starknow:starknow@localhost:5433/starknow`，并确保 `backend/src/config.js` 会读取到该环境变量。

---

## 一、目录与文件

| 文件 | 说明 |
|------|------|
| `starknow-ai-proxy/Dockerfile` | Node 服务镜像构建 |
| `starknow-ai-proxy/.dockerignore` | 构建时忽略 node_modules、.env 等 |
| `docker-compose.yml`（项目根目录） | 编排 **app**（AI 代理）与 **db**（PostgreSQL） |
| `.env.example` | 环境变量示例，复制为 `.env` 后填写 |

## 二、本地运行（Docker）

### 1. 准备环境变量

```bash
cp .env.example .env
# 编辑 .env，至少填写 TENCENT_SECRET_ID、TENCENT_SECRET_KEY（AI 对话/识图用）
```

### 2. 启动

```bash
docker compose up -d
```

- **app**：`http://localhost:3001`（AI 代理、中继等）
- **db**：`localhost:5433`（PostgreSQL，默认库 `starknow`，用户 `starknow`）

### 3. 常用命令

```bash
# 查看日志
docker compose logs -f app

# 仅构建/重启 app
docker compose up -d --build app

# 停止并删除容器（数据卷保留）
docker compose down
```

## 三、数据库（PostgreSQL）

- **镜像**：`postgres:16-alpine`
- **默认**：用户 `starknow`，密码 `starknow`，库 `starknow`
- **数据卷**：`starknow_pgdata`，`docker compose down` 不会删数据
- **建库与建表**：首次或数据目录为空时 `docker compose up -d`，会自动执行 `001_schema.sql`、`002_growth_schema.sql`、`002_seed_user.sql`、`003_growth_seed.sql`（见项目根 `docker-compose.yml` 中 db 的 volumes）；之后若需手动补表或种子，可执行 `backend/sql/` 下对应脚本
- **连接串**（在容器内或后续 server 使用）：  
  `postgres://starknow:starknow@db:5432/starknow`  
  若改了 `.env` 里的 `POSTGRES_*`，则 `DATABASE_URL` 会由 compose 注入为对应值。

### 后续在 server 中接入数据库

1. 在 `starknow-ai-proxy` 里安装驱动，例如：  
   `npm install pg` 或 `npm install pg sequelize` 等。
2. 在 server 中读取 `process.env.DATABASE_URL`，建连接池/ORM，把当前内存里的用户、验证码、会话等逐步迁到表里。
3. 仍不修改现有接口与路由逻辑，只把“存哪里”从内存改为数据库。

## 四、仅本地跑 Node（不用 Docker）

```bash
cd starknow-ai-proxy
npm install
# 设置 TENCENT_SECRET_ID、TENCENT_SECRET_KEY 等
node server.js
```

需要连本机 Docker 里的 Postgres 时，可用：  
`DATABASE_URL=postgres://starknow:starknow@localhost:5433/starknow`（compose 默认映射宿主机 5433）。

## 五、生产部署注意

- 务必修改 `.env` 中 `POSTGRES_PASSWORD` 及腾讯云密钥，不要用示例默认值。
- 可按需给 db 挂备份卷、调大 `healthcheck` 超时等。
