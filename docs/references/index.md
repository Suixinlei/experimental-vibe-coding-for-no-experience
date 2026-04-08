# References Index

> 外部库、框架、CLI 的"llms.txt"类参考文件放在本目录。
> 目的：**把 agent 工作时需要的外部上下文拉进仓库**，避免 agent 在运行时到处抓取（慢、不稳定、且有可能抓错版本）。

## 命名规范

- 每个外部工具一个文件：`<tool>-llms.txt`（或 `.md`）
- 版本敏感的写进文件名：`tool-v1.2-llms.txt`
- 文件首行注明**来源 URL + 抓取日期 + 版本号**

## 当前登记

| 工具 | 文件 | 抓取日期 | 版本 |
|---|---|---|---|
| _(none yet)_ | – | – | – |

## 维护

- 依赖升级时必须同步更新对应的 reference 文件
- doc-gardening agent 会定期检测版本漂移
- 不要放**内部**文档 —— 内部文档应该写在 `docs/design-docs/` 或 `docs/product-specs/`
