# Core Beliefs

> 我们的 **agent-first operating principles**。每一条都应该能在一次评审争论中被明确引用。
> 这个文件是"宪法"，改动需要显式的执行计划。

---

## 1. Humans steer. Agents execute.

人类负责**优先级、验收标准、判断**。agent 负责**生产工件**（代码、测试、文档、评审意见、回复）。
当 agent 卡住，不要"让它再试一次"，去问：**缺了什么能力？** 然后把能力沉淀回仓库。

## 2. Repository knowledge is the system of record.

agent 看不见的东西就不存在。Slack 共识、Google Doc 方案、会议口头约定 —— 在进入仓库前都不作数。
当发现仓库里缺少某条事实时，**先补文档，再继续工作**。

## 3. Give agents a map, not a manual.

AGENTS.md 是目录，不是百科。大块规则要落到 `docs/` 下对应的专题文件，通过链接到达。
monolithic 的指令文件会：(a) 挤占上下文、(b) 让"重要"失去含义、(c) 快速腐烂、(d) 难以机械校验。

## 4. Enforce invariants, not implementations.

我们强约束**边界**（依赖方向、数据解析、日志结构、命名、文件大小），不强约束**实现风格**。
约束用 lint / 结构化测试机械执行，error message 要把**修复指引**注入到 agent 上下文中。

## 5. Parse at the boundary.

所有来自外部（HTTP、DB、文件、env、消息队列）的数据，**在边界处一次性解析成强类型**。
系统内部信任类型，不做重复校验。

## 6. Boring is legible.

生态成熟、API 稳定、训练数据中充分代表的技术 → agent 更容易建模。
**小范围重新实现一段功能** 常常比适配一个不透明的上游库更便宜。

## 7. Throughput changes the merge philosophy.

在 agent 驱动的高吞吐下：**短命 PR、最小阻塞门禁、follow-up 修正** 比 "每个 PR 必须完美" 更划算。
前提是要有足够强的自动验证和 GC。

## 8. Continuous garbage collection.

技术债是高息贷款，**每天还一点**远好于攒到季度末清理。
golden principles → 周期扫描 agent → 小 PR → 快速自动合并。

## 9. Agent legibility first, then human legibility.

代码风格不必总是符合人类偏好。**只要对未来的 agent 运行可读、正确、可维护**，就达标。
当人类和 agent 的可读性冲突时，优先 agent。

## 10. When documentation falls short, promote the rule into code.

一条规则反复被违反 → 把它变成 lint / 结构化测试。
写在 markdown 里的规则会被遗忘；写在 lint 里的规则不会。
