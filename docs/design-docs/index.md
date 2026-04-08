# Design Docs Index

> 所有设计文档在这里登记。
> 每条登记必须含：**标题 · 状态 · 验证状态 · 链接**。
> 没登记的设计文档对 agent 等于不存在。

## 状态定义

- `draft` — 还在讨论
- `accepted` — 已采纳，尚未完全实现
- `implemented` — 已实现
- `superseded` — 被 #XX 替代
- `rejected` — 讨论后否决，保留原因

## 验证状态

- `unverified` — 文档描述是否符合真实代码行为尚未验证
- `verified` — 由 doc-gardening agent 或人工确认过与代码一致
- `stale` — 已检测到与代码不符，待修

## 登记表

| # | 标题 | 状态 | 验证 | 链接 |
|---|---|---|---|---|
| 001 | 核心信念 | accepted | verified | [core-beliefs.md](./core-beliefs.md) |

> 进行中的工作请去 [`docs/exec-plans/active/`](../exec-plans/active/) 而不是这里。
> 当前活跃计划：[2026-04-08 bootstrap](../exec-plans/active/2026-04-08-bootstrap.md)

_新增条目时请**按编号递增**，不要复用编号。_
