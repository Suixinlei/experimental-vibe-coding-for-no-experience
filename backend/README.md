# backend

Bun + Elysia + bun:sqlite. 这是 iOS App 对应的服务端。

## 快速开始

```bash
cd backend

# 1) 装依赖（首次或更新 package.json 后）
bun install

# 2) 复制环境变量
cp .env.example .env

# 3) 跑 migration（首次会创建 data/app.db）
bun run migrate

# 4) 起开发服务（hot reload）
bun run dev
```

服务起来后：
- API: http://127.0.0.1:3000
- 健康检查: http://127.0.0.1:3000/health
- OpenAPI / Swagger UI: http://127.0.0.1:3000/openapi
- OpenAPI JSON: http://127.0.0.1:3000/openapi/json

## 目录结构

```
backend/
├── package.json
├── tsconfig.json
├── .env.example
├── data/                      # SQLite 文件落地处（gitignored，仅保留 .gitkeep）
└── src/
    ├── index.ts               # 入口：组合插件、起 HTTP server
    ├── env.ts                 # 边界处解析环境变量（parse, don't validate）
    ├── db/
    │   ├── index.ts           # bun:sqlite 单例
    │   ├── migrate.ts         # 简易迁移 runner
    │   └── migrations/
    │       └── 0001_init.sql  # 初始 migration
    └── modules/               # 每个业务模块一个文件夹（feature-based）
        └── health/
            ├── index.ts       # controller（HTTP 路由 + 校验）
            ├── service.ts     # 业务逻辑（与 Elysia 解耦）
            └── model.ts       # 请求/响应 schema（TypeBox via `t`）
```

新增业务模块时遵循 `health/` 的三件套：`index.ts` / `service.ts` / `model.ts`。

## 与 iOS 端的契约

iOS 客户端**不手写** API 调用。开发流程：

1. backend 改完路由后，访问 `/openapi/json` 拿到最新 OpenAPI spec
2. 用 `swift-openapi-generator` 在 iOS 工程里 codegen Swift 客户端
3. iOS 端只调用生成的 client，类型安全由 OpenAPI 保证

> Bun 的 SQLite 驱动是原生 C 绑定（`bun:sqlite`），不需要 `better-sqlite3` 这类 npm 包，启动几乎零成本。

## 一些约定（来自 docs/design-docs/core-beliefs.md）

- 边界处 parse（环境变量、HTTP 请求体、DB 行）→ 见 `env.ts` + Elysia 的 `t.Object`
- 业务逻辑放 `service.ts`，不要塞进 controller —— 这样能脱离 Elysia 单测
- 不手搓 helpers，先看 `src/` 下有没有共享工具
- 不裸 `console.log`，待 OTel 接入后用结构化 logger
