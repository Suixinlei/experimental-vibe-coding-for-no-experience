# AGENTS.md

> 本文件是 **agent 的入口地图**，不是百科全书。
> 保持精简（目标 ≤ 100 行）。遇到"需要更多上下文"时，**跳转到 docs/ 下的对应文件**，而不是在这里堆叠规则。

## 这个仓库是什么

一个实验项目：探索在"no-experience"条件下，以 agent 为主力完成软件构建的工作流与脚手架。
参考范式：OpenAI 《Harness engineering: leveraging Codex in an agent-first world》(2026-02-11)。

核心约束：
- **人类掌舵，agent 执行**（Humans steer. Agents execute.）
- **仓库即事实来源**（Repository knowledge is the system of record）
- **agent 看不见的东西就不存在**（若信息只在 Slack / Google Doc / 某人脑中，对 agent 等同于不存在 → 必须落盘到仓库 markdown）

## 从这里开始导航

| 你想做的事 | 去哪里 |
|---|---|
| 了解顶层架构与分层边界 | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| 理解设计原则与"核心信念" | [docs/design-docs/core-beliefs.md](./docs/design-docs/core-beliefs.md) |
| 查看所有设计文档索引 | [docs/design-docs/index.md](./docs/design-docs/index.md) |
| 了解产品定位与用户场景 | [docs/product-specs/index.md](./docs/product-specs/index.md) |
| 写/跟进一个执行计划 | [docs/PLANS.md](./docs/PLANS.md) + [docs/exec-plans/](./docs/exec-plans/) |
| 查技术债 | [docs/exec-plans/tech-debt-tracker.md](./docs/exec-plans/tech-debt-tracker.md) |
| 设计系统 / 样式约定 | [docs/DESIGN.md](./docs/DESIGN.md) · [docs/FRONTEND.md](./docs/FRONTEND.md) |
| 产品直觉与审美 | [docs/PRODUCT_SENSE.md](./docs/PRODUCT_SENSE.md) |
| 各领域的质量评分 | [docs/QUALITY_SCORE.md](./docs/QUALITY_SCORE.md) |
| 可靠性 SLO / 错误预算 | [docs/RELIABILITY.md](./docs/RELIABILITY.md) |
| 安全基线 | [docs/SECURITY.md](./docs/SECURITY.md) |
| 外部库/工具的 llms.txt 参考 | [docs/references/index.md](./docs/references/index.md) |
| 自动生成的工件（DB schema 等） | [docs/generated/](./docs/generated/) |

## 工作流铁律（任何变更都适用）

1. **先计划，后动手**。任何非 trivial 的改动都要先写一个轻量 plan（见 `docs/PLANS.md`）。复杂工作用 `docs/exec-plans/active/` 下的执行计划。
2. **边界处解析数据**（parse, don't validate）。所有外部输入在进入系统边界时就解析成强类型。
3. **优先复用共享工具包**，不要手搓辅助函数 —— 保持不变式集中。
4. **不 YOLO 探测数据形状** —— 要么校验边界，要么用有类型的 SDK。
5. **结构化日志 + OTel 追踪**是一等公民，不是事后补丁。
6. **文档即代码**：信息如果没落到仓库里，就等于不存在。遇到"口头约定"时，先把它写进 `docs/`，再继续。
7. **修 bug 时问的不是"怎么绕过"而是"缺了什么能力"**。缺的能力要回流到仓库（工具 / 文档 / lint）。

## 给 agent 的"禁止事项"

- ❌ 不要把规则堆进这个文件 —— 它只做导航。新规则写到对应的 `docs/*.md`。
- ❌ 不要创建没在上表中登记的顶层目录。
- ❌ 不要在没有执行计划（plan）的情况下开始非 trivial 的改动。
- ❌ 不要在评审中用"看起来能工作"作为合入理由 —— 需要可复现的验证。

## 给人类的说明

这个仓库是按 **agent legibility first** 组织的。如果你作为人类读起来觉得啰嗦 / 过度显式 / 样板过多 —— 那通常是**刻意的**：这些结构是 agent 的导航信号。

要改动本文件，请先读一遍 OpenAI Harness engineering 原文：
https://openai.com/index/harness-engineering/
