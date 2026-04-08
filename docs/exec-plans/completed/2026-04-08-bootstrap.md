# 2026-04-08 — bootstrap

> 从空仓库到"backend 能起、health 通、iOS 工程脚手架就绪"的第一个执行计划。
> 状态：**进行中**

## 目标

把这个 monorepo 从 0 推进到一个最小可演进的状态：

1. ✅ 仓库知识结构（`docs/` + `AGENTS.md` + `ARCHITECTURE.md`）按 OpenAI Harness Engineering 的做法落盘
2. ✅ backend 能本地跑通：Bun + Elysia + bun:sqlite，含 health 接口、OpenAPI 自动文档、迁移系统
3. ⏳ Xcode 命令行可用 + iOS 模拟器列出
4. ⏳ iOS 工程生成（SwiftUI + iOS 17，依赖 swift-openapi-generator）
5. ⏳ iOS 调用 `/health` 端到端打通

## 非目标

- ❌ 不做任何业务功能（首版只是脚手架，等业务方向确定再开新计划）
- ❌ 不接 OTel / 完整可观测性栈（等服务有真实流量再做）
- ❌ 不做 auth / 用户系统（等业务需要再做）
- ❌ 不做 CI / lint enforcement（先让东西跑起来，下一个计划做工程化）

## 方案

### 阶段 1 — 仓库骨架 ✅

按 Harness Engineering 文章的 layout 创建 `AGENTS.md` / `ARCHITECTURE.md` / `docs/{design-docs,exec-plans,product-specs,references,generated}` + 7 个顶层 docs/*.md 文件。

### 阶段 2 — backend ✅

- `backend/` 目录，feature-based 结构（`src/modules/<feature>/{index,service,model}.ts`）
- 依赖：`elysia` `@elysiajs/openapi` `@elysiajs/cors` `@sinclair/typebox`
- `src/env.ts`：边界处用 TypeBox `Value.Cast` 解析环境变量（parse, don't validate）
- `src/db/index.ts`：bun:sqlite 单例，开 WAL + foreign_keys + busy_timeout
- `src/db/migrate.ts`：手搓 forward-only migration runner（用 `schema_migrations` 表追踪），刻意不用 drizzle-kit —— 复杂度还没到
- `src/modules/health/`：示范性 module，三件套齐全
- `src/index.ts`：组合 cors + openapi + health module，listen
- 验证通过：`bun run typecheck` ✅、`bun run migrate` 幂等 ✅、`/health` 200 ✅、`/openapi/json` 200 ✅

### 阶段 3 — Xcode 命令行 ⏳ ←现在在这

人类执行：
```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -version
xcrun simctl list devices available | grep iPhone
```

agent 验证：`xcodebuild -version` 输出版本、`simctl` 列出至少一个 iPhone 模拟器。

### 阶段 4 — iOS 工程生成 ⏳

通过 Xcode GUI 创建 `ios/App` 工程（SwiftUI / Swift / iOS 17 / no tests / no SwiftData）。
理由：用 GUI 而不是 `xcodegen`/Tuist，因为这只是首次创建，后续维护成本更低；当工程结构稳定后再考虑生成式工具。

### 阶段 5 — 端到端 health 调用 ⏳

- 加 SwiftPM 依赖：`swift-openapi-generator` + `swift-openapi-runtime` + `swift-openapi-urlsession`
- 把 `http://127.0.0.1:3000/openapi/json` 拉成 `ios/App/openapi.yaml`
- 配 codegen，生成 Swift client
- ContentView 里调 `client.healthCheck()`，把 `status` / `uptime_seconds` / `db.schema_version` 显示出来
- 模拟器跑通 = 整条链路通

## 风险与未知

| # | 风险 | 应对 |
|---|---|---|
| R1 | 模拟器访问 127.0.0.1 不通 | iOS 模拟器和 host 共享网络栈，正常情况下 OK；如不通退化为 `localhost` 或局域网 IP |
| R2 | OpenAPI 3.0.3 与 swift-openapi-generator 兼容性 | swift-openapi-generator 支持 3.0 和 3.1；@elysiajs/openapi 输出 3.0.3 ✅ |
| R3 | bun:sqlite 在某些 macOS 版本上的兼容 | 已经在本机验证 ✅ |
| R4 | iOS 17 最低版本是否过高 | 17 已发布 1.5+ 年，覆盖率足够；如有具体业务要求覆盖更低版本再降 |

## 进度日志

- **2026-04-08 10:39** — 仓库知识库骨架完成（17 个文件）
- **2026-04-08 11:00** — 用户拍板：Bun + Elysia 后端，monorepo 结构
- **2026-04-08 11:01** — backend 目录骨架 + 所有源文件写入
- **2026-04-08 11:02** — `bun install` 成功（54 包，2.16s）
- **2026-04-08 11:02** — `bun run typecheck` 通过（无错误）
- **2026-04-08 11:03** — `bun run migrate` 通过 + 幂等性验证
- **2026-04-08 11:03** — backend 启动，`/health` 返回 `{"status":"ok","db":{"reachable":true,"schema_version":"0001_init"}}` ✅
- **2026-04-08 11:04** — 用户报告 Xcode 安装完成，准备进入阶段 3

## 决策日志

- **D1** — **手搓 migration runner 而非用 drizzle-kit**：核心信念 #6 (boring is legible)。当前没有多人并发改 schema 的需求，30 行代码搞定的事不值得引入一个 ORM 工具链。当出现"分支并发改 schema"或"需要 down migration"时升级到 drizzle。
- **D2** — **`@sinclair/typebox` 作为显式依赖而非依赖 Elysia 传递导出**：env 解析使用了 `Value.Cast`，必须从 typebox 直接 import；显式依赖比依赖 transitive 更稳。
- **D3** — **iOS 用 swift-openapi-generator 而非手写 URLSession**：契约同步是高成本错误源，让 codegen 处理；同时这条强制了 backend 改完必须刷 OpenAPI 的纪律。
- **D4** — **暂不接 OTel / 结构化 logger**：核心信念 #10 (rule into code)。等真有 traffic 后再做，否则现在加只是噪音。当前 `console.log` 仅用于服务启动横幅。
- **D5** — **CORS 默认 `*`**：仅 dev。上线前必须收紧到具体 origin —— 已记入 `tech-debt-tracker.md`。
