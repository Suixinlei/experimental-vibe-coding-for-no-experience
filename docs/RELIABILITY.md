# RELIABILITY.md

> 可靠性目标、SLO、错误预算、可观测性约定。

## 核心理念

Harness engineering 原文把可观测性视为 agent 的**输入通道**：
- agent 查 Logs（LogQL）、Metrics（PromQL）、Traces 来复现 bug 和验证修复
- 每个任务在**独立的 worktree**里启动完整的本地 observability stack，结束即销毁

这意味着：**日志/指标/追踪不是事后补丁，是 agent 工作流的一部分**。

## SLO（目标态）

_TODO：等首个生产面服务落地后填具体数字。_

## 可观测性基线（任何服务必须满足）

- [ ] **结构化日志**：JSON 或等价格式，禁止裸 `print` / `console.log`
- [ ] **OpenTelemetry trace**：关键路径必须打 span
- [ ] **RED 指标**（Rate / Errors / Duration）自动采集
- [ ] **健康检查端点**
- [ ] **启动耗时 budget**（如：服务启动 < 800ms）
- [ ] **关键用户旅程 latency budget**（如：任何 span < 2s）

## 本地可观测性栈（agent 使用）

目标栈（参考文章）：
- **Vector** 作为采集器
- **VictoriaLogs** → LogQL
- **VictoriaMetrics** → PromQL
- **VictoriaTraces** → TraceQL

_尚未搭建。落地时请登记启动脚本位置。_

## 错误预算政策

_TODO_
