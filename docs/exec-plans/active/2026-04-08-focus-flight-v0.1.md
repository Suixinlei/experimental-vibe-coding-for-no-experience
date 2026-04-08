# 2026-04-08 — Focus Flight V0.1

> 从 `bootstrap` 完成后的脚手架 → Focus Flight V0.1 端到端 demo。
> 状态：**进行中**
> 前置计划：[completed/2026-04-08-bootstrap.md](../completed/2026-04-08-bootstrap.md)
> Product spec：[../../product-specs/001-focus-flight.md](../../product-specs/001-focus-flight.md)

## 目标

跑通一条完整链路：

```
iOS (SwiftUI)
  → POST /users/ensure   (匿名 UUID + 昵称)
  → GET /flights/random  (随机航班)
  → [本地 25 分钟倒计时]
  → POST /sessions       (上报完成)
  → GET /leaderboard     (显示排名)
```

以及把这些用户可见的部件搭起来：
- 首次启动的昵称输入
- 主界面：飞机舷窗 UI + Ken-Burns 背景动画 + 倒计时
- 排行榜界面（Today / All-time 两个 tab）

## 非目标（严格卡在 V0.1）

见 [`product-specs/001-focus-flight.md` § V0.1 范围/不做](../../product-specs/001-focus-flight.md)。
**任何"顺手加一下"的冲动都应该被写进本文件或 tech-debt-tracker，不是当场加。**

## 方案

### 阶段 A — backend 扩展

**A.1 migration `0002_focus_flight.sql`**
```sql
CREATE TABLE users (
  uuid TEXT PRIMARY KEY,
  nickname TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_seen_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_uuid TEXT NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
  flight_code TEXT NOT NULL,
  destination TEXT NOT NULL,
  started_at TEXT NOT NULL,
  completed_at TEXT NOT NULL,
  focus_minutes INTEGER NOT NULL CHECK (focus_minutes > 0)
);

CREATE INDEX idx_sessions_user ON sessions(user_uuid);
CREATE INDEX idx_sessions_completed_at ON sessions(completed_at);
```

**A.2 `src/modules/flights/`**
- `data/flights.json`：从杭州出发的 10 条航班种子数据
- `service.ts`：读 JSON + 随机选一条
- `model.ts`：`t.Object({ code, destination, country, duration_h, image_urls })`
- `index.ts`：`GET /flights/random`

**A.3 `src/modules/focus/`**
- `repo.ts`：封装所有 SQL（`upsertUser`, `insertSession`, `leaderboard`）
- `service.ts`：业务逻辑，校验 `started_at < completed_at`
- `model.ts`：`UserEnsureBody`, `SessionCreateBody`, `LeaderboardEntry`
- `index.ts`：3 条路由

**A.4 在 `src/index.ts` mount 新模块**

### 阶段 B — backend 验证

```bash
bun run typecheck
bun run migrate
bun run dev &
curl -s http://127.0.0.1:3000/health
curl -s http://127.0.0.1:3000/flights/random
curl -s -X POST http://127.0.0.1:3000/users/ensure \
  -H 'content-type: application/json' \
  -d '{"uuid":"test-uuid-1","nickname":"tester"}'
curl -s -X POST http://127.0.0.1:3000/sessions \
  -H 'content-type: application/json' \
  -d '{"user_uuid":"test-uuid-1","flight_code":"CZ3123","destination":"Bangkok","started_at":"2026-04-08T12:00:00Z","completed_at":"2026-04-08T12:25:00Z","focus_minutes":25}'
curl -s 'http://127.0.0.1:3000/leaderboard?period=today&limit=10'
```

全部 200 且语义正确 = 后端过关。

### 阶段 C — 人类：Xcode GUI 新建工程

按 `xcode-setup-guide.md`（本目录下）逐屏操作。

**产物位置**：`ios/App/` (含 `App.xcodeproj`、`App/` 源码目录)

产出后告诉我，我进入阶段 D。

### 阶段 D — iOS 实现

D.1 把后端的 `/openapi/json` 存为 `ios/App/openapi.yaml`
D.2 Xcode 加 SwiftPM 依赖：
  - `https://github.com/apple/swift-openapi-generator`
  - `https://github.com/apple/swift-openapi-runtime`
  - `https://github.com/apple/swift-openapi-urlsession`
D.3 配 `openapi-generator-config.yaml`，build phase 跑 codegen
D.4 实现文件结构：
```
ios/App/App/
├── AppApp.swift            # @main
├── Identity/
│   ├── IdentityStore.swift      # 管理 device UUID + nickname 持久化
│   └── NicknameSetupView.swift  # 首次启动昵称输入
├── Flight/
│   ├── FlightViewModel.swift    # 倒计时 + session 上报
│   ├── FlightView.swift         # 舷窗主界面
│   ├── WindowMask.swift         # 舷窗形状 shape
│   └── KenBurns.swift           # 背景图慢平移+缩放 modifier
├── Leaderboard/
│   ├── LeaderboardViewModel.swift
│   └── LeaderboardView.swift
└── API/
    └── Client+Convenience.swift # 封装 codegen client,统一错误类型
```

D.5 在模拟器跑一次完整循环

### 阶段 E — 端到端 demo 录屏

模拟器跑完一次 25 分钟（或临时把 Timer 改成 25s 测试）+ 上报 + 看到排行榜 = 过关。

## 风险与未知

| # | 风险 | 应对 |
|---|---|---|
| R1 | Unsplash 直链可能 rate limit 或失效 | 挑稳定的 CDN URL；最差 fallback 到 SF Symbols 地图 icon + 渐变背景 |
| R2 | SwiftUI Ken-Burns 效果可能"塑料感" | 多层视差（远景静止、中景慢平移、云层更慢）+ 轻微 blur 过渡 |
| R3 | iOS 模拟器访问 127.0.0.1 的 backend | 模拟器和 host 共享网络栈，正常可直连 |
| R4 | swift-openapi-generator 对某些 Elysia 出的 schema 语法不兼容 | 最差退化手写 URLSession（仍然照着 spec 写类型），作为 TD 登记 |
| R5 | V0.1 没做中断检测，用户切后台会不会崩 | iOS 后台 Timer 停止→重入 foreground 用真实时间差补齐；超过 10s 视为失败 |

## 进度日志

- **2026-04-08 11:04** — bootstrap 归档,本计划建立
- **2026-04-08 11:04** — product spec 001 落盘
- **2026-04-08 11:30** — 用户完成 Xcode GUI 新建 `ios/PomodAero` (iOS 26.4 target, Swift 5, PBXFileSystemSynchronizedRootGroup)
- **2026-04-08 11:31** — backend 扩展完成: migration 0002, flights module, focus module. 8 个 endpoint 验证全绿(含 400/404 语义错误路径)
- **2026-04-08 11:35** — iOS 源码全部写入 (API × 2, Identity × 2, Flight × 4, Leaderboard × 1, 根 × 2 共 11 个 Swift 文件)
- **2026-04-08 11:40** — 首次 xcodebuild 失败: 2 个编译错误 (Self 在 stored property init 不可用; @MainActor APIClient.shared 作默认参数 Swift 6 报错)
- **2026-04-08 11:43** — 修复后 **BUILD SUCCEEDED** (iPhone 17 Pro Simulator, Debug)

## 决策日志

- **D1 — 静态图 + Ken-Burns 而非 MP4**
  V0.1 降低资源依赖。接口层面预留 `image_urls` 与 `video_url` 的 union,后续切换零成本。
- **D2 — 匿名 device UUID 而非 Sign in with Apple**
  验证产品假设的速度 > 账户体系完整性。换手机会丢数据 —— 首版可接受。
- **D3 — 固定 25 分钟**
  变量一次只引入一个。首版连可调时长都不做,专注于"起飞→降落"的叙事闭环。
- **D4 — 不做短休暂停/恢复**
  状态机越简单越好。真的需要短休就退出再开一次。
- **D5 — flights 数据走 JSON 文件而非数据库表**
  10 条数据、纯读、不由用户产生 —— 入库只会增加 migration 负担且没任何收益。JSON 即真理。
- **D6 — focus 模块引入独立的 repo.ts**
  health 模块只有一件事,直接在 service 里写 SQL 没问题。focus 有多张表 + 聚合查询,把 SQL 集中在 repo.ts 有助于未来替换为 query builder。
- **D7 — iOS 暂不用 swift-openapi-generator**
  V0.1 只有 4 个端点,60 行手写 URLSession + Codable 足够。避免引 SwiftPM 依赖 + pbxproj 编辑风险。登记为 TD-004,当端点超过 10 个或 schema 开始频繁变动时升级。
- **D8 — APIClient 标 `nonisolated`**
  Xcode 26 工程默认 `-default-isolation=MainActor`,会让无状态的 HTTP 客户端被绑到 MainActor,作为默认参数时 Swift 6 会报错。APIClient 没有可变状态 → 显式 `nonisolated final class APIClient: Sendable`。这是"默认 MainActor"时代的新手坑,未来所有纯服务类都要注意。
- **D9 — 嵌套 .git 用 rename 而非 delete**
  用户在 Xcode GUI 新建时勾了 "Create Git repository on my Mac",`ios/PomodAero/.git` 成了独立仓库。用 `mv .git .git.bak` 保留可逆性而非直接删。已加入 .gitignore。
