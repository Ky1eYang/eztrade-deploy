# Star Service Deploy

该仓库用于一键部署以下 3 个镜像：

- `ky1eyang/star-dashboard`
- `ky1eyang/star-platform`
- `ky1eyang/eztrade-server`

并支持 PostgreSQL + Redis 两种模式：

- 本地容器模式（`docker compose` 同时拉起 `postgres`/`redis`）
- 外部服务模式（使用宿主机或远端 PostgreSQL/Redis）

## 目录结构

```text
star-service-deploy/
├── .env.template
├── docker-compose.yml
├── postgres/
│   └── init/
│       └── 01-init.sql
├── redis/
│   └── redis.conf.template
└── eztrade/
    ├── config/
    │   └── cfg.toml.template
    └── certs/
        └── README.md
```

## 1. 初始化（首次）

在 [star-service-deploy/.env.template](.env.template) 基础上创建本地配置：

```bash
cp .env.template .env
cp redis/redis.conf.template redis/redis.conf
cp eztrade/config/cfg.toml.template eztrade/config/cfg.toml
```

然后填写这 3 个文件中的敏感信息（密码、API Key、远端地址）。

## 2. postgres/redis 开关

开关通过 `.env` 的 `COMPOSE_PROFILES` 控制：

1. 使用本地容器 postgres/redis：`COMPOSE_PROFILES=local-infra`
2. 使用外部 postgres/redis：`COMPOSE_PROFILES=`（留空）

外部模式时，至少要改这些变量：

1. `STAR_PLATFORM_REDIS_URL`
2. `STAR_PLATFORM_DATABASE_URL`
3. `DASHBOARD_REDIS_HOST`
4. `DASHBOARD_REDIS_PORT`
5. `DASHBOARD_REDIS_USERNAME`
6. `DASHBOARD_REDIS_PASSWORD`
7. `DASHBOARD_TRADE_DB_URL`
8. `eztrade/config/cfg.toml` 里的 `redis_url` 与 `pgsql_url`

## 3. 启动与停止

```bash
docker compose pull
docker compose up -d
```

```bash
docker compose ps
docker compose logs -f --tail=200
```

```bash
docker compose down
```

## 服务端口

- `star-dashboard`: `3000`
- `star-platform`: `7800`
- `eztrade-server`: `7878`
- `postgres`: `5432`（仅 `local-infra`）
- `redis`: `6379`（仅 `local-infra`）

## 环境变量来源

`docker-compose.yml` 中敏感项已改为 `${...}` 读取 `.env`。

可提交到 Git 的模板文件：

1. [star-service-deploy/.env.template](.env.template)
2. [star-service-deploy/redis/redis.conf.template](redis/redis.conf.template)
3. [star-service-deploy/eztrade/config/cfg.toml.template](eztrade/config/cfg.toml.template)

本地私有文件（已 `.gitignore`）：

1. `.env`
2. `redis/redis.conf`
3. `eztrade/config/cfg.toml`

## 可选：启用 eztrade TLS

1. 在 `eztrade/certs/` 放入 `cert.pem` 与 `key.pem`
2. 修改 `eztrade/config/cfg.toml` 中 `tls_enabled = true`
3. 修改 `.env` 中 `DASHBOARD_SANDBOX_BACKEND_URL=https://eztrade-server:7878`

## 首次检查建议

```bash
curl http://127.0.0.1:7800/v1/healthz
curl http://127.0.0.1:3000
```

