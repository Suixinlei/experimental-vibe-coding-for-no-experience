# Tech Debt Tracker

> 集中登记已知技术债。每一条都要能被"还"（有明确的还款路径）。
> 由 agent 定期扫描更新；人类在评审中发现新的债务也要登记。

## 格式

每条债务：

```
### [TD-NNN] <一句话标题>
- 发现于: YYYY-MM-DD
- 位置: <路径 / 域>
- 影响: <阻塞了什么，增加了多少成本>
- 建议方案: <一句话>
- 预估工作量: S / M / L
- 状态: open / in-progress (→ PR#xxx) / closed (→ PR#xxx)
```

## 开放项

### [TD-001] CORS 默认开放为 `*`
- 发现于: 2026-04-08
- 位置: `backend/.env.example` · `backend/src/index.ts`
- 影响: 仅适合 dev。生产部署前必须收紧到具体 origin 列表，否则任何站点都能直接调 API。
- 建议方案: 上线前在 `.env` 中设 `CORS_ORIGINS=https://<prod-host>`；考虑在 `env.ts` 里增加"NODE_ENV=production 时禁止 `*`"的硬校验。
- 预估工作量: S
- 状态: open

### [TD-002] 没有结构化 logger / OTel
- 发现于: 2026-04-08
- 位置: `backend/src/index.ts`（启动时用裸 `console.log`）
- 影响: 违反 core-beliefs 第 10 条与 RELIABILITY.md 的基线。在没有真实流量前可以接受。
- 建议方案: 接 `pino` 或 OpenTelemetry SDK；把 `onStart` 横幅 + 请求日志统一走 logger。
- 预估工作量: M
- 状态: open

### [TD-003] migration runner 是手搓的
- 发现于: 2026-04-08
- 位置: `backend/src/db/migrate.ts`
- 影响: 当前够用。一旦出现并发改 schema、需要 down migration、或 schema 复杂到需要 type-safe query builder 时，会显著拖慢速度。
- 建议方案: 升级到 drizzle-kit；保留 SQL 文件作为 source of truth。
- 预估工作量: M
- 状态: open

### [TD-004] iOS 工程的 codegen 流程未自动化
- 发现于: 2026-04-08
- 位置: `ios/`（待生成）
- 影响: backend 改完路由后，iOS 端要手动重拉 `/openapi/json`。容易忘。
- 建议方案: pre-commit 钩子或 Xcode build phase：起本地服务 → 拉 spec → diff → 失败时阻塞。
- 预估工作量: M
- 状态: open

## 已关闭

_（空）_
