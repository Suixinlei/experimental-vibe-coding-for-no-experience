# DESIGN.md

> 跨业务域的通用设计原则与设计系统指引。
> 具体的单个设计决策写到 `docs/design-docs/<topic>.md`，本文件只保留**横跨所有域的通用规范**。

## 设计哲学

1. **Boring is good**：优先选择生态成熟、API 稳定、训练数据中充分代表的"无聊"技术，因为它们对 agent 更可读。
2. **小而内聚的依赖**：宁可自己实现一个紧耦合的 300 行辅助，也不要拉入一个行为不透明的大库。
3. **边界处解析**（Parse, don't validate）：外部数据一进系统就变成强类型。
4. **显式优于隐式**：显式的配置、显式的依赖注入、显式的错误类型。

## 设计系统

_TODO：当 UI 落地后，链接到设计 token、组件库、排版规范。_

## 参考

- Parse, don't validate: https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/
- AI is forcing us to write good code: https://bits.logic.inc/p/ai-is-forcing-us-to-write-good-code
