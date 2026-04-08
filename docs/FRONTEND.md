# FRONTEND.md

> 前端专属约定。只有当前端栈实际存在时本文件才有意义。

## 状态

**前端尚未建立**。本文件作为占位，一旦引入前端栈请在此登记：
- 框架选型（React / Vue / Svelte / ...）
- 状态管理方案
- 样式方案（CSS Modules / Tailwind / CSS-in-JS）
- 路由方案
- 构建工具
- 设计系统位置

## agent 可观测性要求（预告）

按 Harness engineering 的经验，前端落地后需要同步提供：
- **可按 git worktree 启动**的本地实例，保证 agent 每个任务独立运行一个 app
- **Chrome DevTools Protocol 钩子**（DOM 快照、截图、导航）供 agent 自驱验证
- **DOM 语义标注**（如稳定的 `data-testid`）保证 agent 能引用元素
