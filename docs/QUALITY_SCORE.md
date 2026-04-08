# QUALITY_SCORE.md

> 对每个业务域与架构层的**质量打分**。本文件是"差距地图"：让 agent 和人类都能看到哪里欠债最多。

## 评分维度

每个 (域 × 层) 格子打 0–5 分：

| 分数 | 含义 |
|---|---|
| 5 | 完整 · 有测试 · 有文档 · 有监控 · 无已知 tech debt |
| 4 | 功能完整 · 有测试，但监控或文档欠缺 |
| 3 | 功能可用，测试覆盖不全 |
| 2 | 有占位实现，但关键路径未覆盖 |
| 1 | 骨架存在，基本不可用 |
| 0 | 未开始 |

## 当前评分

backend 已起脚手架（health module 三件套齐全 + migration runner + OpenAPI 自动出文档）。
iOS 工程尚未生成。

| Domain \ Layer | Types | Config | Repo | Service | Runtime | UI |
|---|---|---|---|---|---|---|
| backend / health | 3 | 3 | – | 3 | 3 | – |
| backend / infra (db, env, migrate) | 3 | 3 | 3 | – | 3 | – |
| ios / – | 0 | 0 | 0 | 0 | 0 | 0 |

**说明**：health 模块拿 3 分而非 5 分，因为：
- 没有单元测试（service 已和 controller 解耦，可补）
- 没有结构化日志 / 监控
- 见 [tech-debt-tracker.md](./exec-plans/tech-debt-tracker.md) TD-002

## 已知技术债

详见 [exec-plans/tech-debt-tracker.md](./exec-plans/tech-debt-tracker.md)。

## 更新规则

- 每次 merge 重要变更时顺手更新对应格子
- "doc-gardening" / "quality-grading" agent 会定期扫描并提 PR 调整分数
- 分数**只能基于仓库中可观察的事实**，不能基于"感觉"
