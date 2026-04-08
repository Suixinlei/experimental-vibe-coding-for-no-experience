# PLANS.md

> 计划（Plans）是一等公民。本文件说明**计划怎么写、存哪里、什么时候升级**。

## 两种计划

### 1. 轻量计划（Lightweight / Ephemeral）

- **用于**：小改动（新增一个函数、修一个 bug、调一条文案）
- **存活周期**：随 PR 结束而消亡，不入库
- **形式**：PR 描述 / 对话中的一段 markdown
- **内容**：目标 · 步骤 · 预期验证方式

### 2. 执行计划（Execution Plan）

- **用于**：复杂改动（新业务域、跨层重构、外部集成）
- **存活周期**：**入库**，持续更新进度与决策日志
- **存放位置**：
  - 进行中 → `docs/exec-plans/active/<YYYY-MM-DD>-<slug>.md`
  - 完成后 → `docs/exec-plans/completed/<YYYY-MM-DD>-<slug>.md`（移动，不删除）
- **必含小节**：
  1. **目标** —— 为什么做，成功标准是什么
  2. **非目标** —— 明确不做什么
  3. **方案** —— 分步拆解
  4. **风险与未知** —— 需要人类判断的点要标出来
  5. **进度日志** —— 追加式记录每次推进
  6. **决策日志** —— 关键决策 + 原因（不要只留结论）

## 什么时候必须用执行计划

- 改动涉及 ≥ 3 个包 / 业务域
- 引入新的外部依赖
- 修改架构不变式（`ARCHITECTURE.md` 或 lint 规则）
- 预计 PR 数 ≥ 2

## 模板

参考 OpenAI Cookbook 的 exec-plans 模板：
https://cookbook.openai.com/articles/codex_exec_plans
