# ARCHITECTURE.md

> 顶层架构地图。参考 matklad 的 [ARCHITECTURE.md 模式](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html)：
> 一个新人（或新 agent）读完本文后，应该能大致回答"某个功能的代码在哪里"。

## 现状

Monorepo，含两个顶层目录：

| 目录 | 内容 | 技术栈 |
|---|---|---|
| [`ios/`](./ios/) | 原生 iOS App | Swift + SwiftUI（待 Xcode 装完后生成工程） |
| [`backend/`](./backend/) | HTTP API + 数据持久化 | Bun + Elysia + bun:sqlite |
| [`docs/`](./docs/) | 仓库知识库（system of record） | markdown |

两个产物之间的契约通过 backend 暴露的 **OpenAPI spec**（由 `@elysiajs/openapi` 自动生成）传递。iOS 端从该 spec 生成 Swift 客户端，而非手写。

业务域尚未落地，仅有一个 `health` 模块作为脚手架样板。

## 分层模型（目标状态）

参考 OpenAI Harness engineering 中的分层架构：每个业务域内部严格按单向依赖分层，跨域只能通过 `Providers` 进入。

```
            ┌─────────────────────────────────────┐
            │        Business Domain (e.g. X)     │
            │                                     │
 Providers ─┼──▶ Service ──▶ Runtime ──▶ UI       │
  (auth,    │      ▲                              │
   conn,    │      │                              │
   telemetry│   Types ──▶ Config ──▶ Repo         │
   flags)   │                                     │
            └─────────────────────────────────────┘
                         ▲
                         │
                    App Wiring + UI
```

依赖方向规则：
- **Types → Config → Repo → Service → Runtime → UI**（仅允许正向依赖）
- **Providers** 是**唯一**的跨域/横切关注点入口（auth / connectors / telemetry / feature flags）
- `Utils` 在业务域外，只能被 `Providers` 消费
- 任何违反上述边界的依赖由 lint / 结构化测试**机械地阻止**

## 业务域（Business Domains）

> 每个业务域在此登记一行，链接到它自己的 `docs/design-docs/<domain>.md`。

_暂无。首个业务域登记后请在此补全。_

## 横切关注点（Cross-Cutting）

| 关注点 | 状态 | 说明 |
|---|---|---|
| Auth | TODO | 通过 Providers 层注入 |
| Telemetry (logs/metrics/traces) | TODO | 结构化日志 + OTel，参见 `docs/RELIABILITY.md` |
| Feature flags | TODO | 通过 Providers 层注入 |
| Connectors（外部系统） | TODO | 通过 Providers 层注入 |

## 不变式（Invariants）

这些由 lint / 结构化测试保证，不靠人盯：

- [ ] 业务域之间**禁止**直接 import
- [ ] 跨层依赖方向**单向**
- [ ] 边界处**必须** parse（不只是 validate）
- [ ] 日志**必须**结构化（禁止裸 `console.log` / `print`）
- [ ] 单文件行数上限（待定，建议 ≤ 500）

## 相关文档

- 设计原则：[docs/design-docs/core-beliefs.md](./docs/design-docs/core-beliefs.md)
- 质量评分：[docs/QUALITY_SCORE.md](./docs/QUALITY_SCORE.md)
- 可靠性：[docs/RELIABILITY.md](./docs/RELIABILITY.md)
- 安全：[docs/SECURITY.md](./docs/SECURITY.md)
