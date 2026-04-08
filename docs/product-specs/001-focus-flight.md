---
spec: 001
name: Focus Flight
status: draft
version: V0.1
owner: human (product) + agents (impl)
created: 2026-04-08
---

# 001 — Focus Flight

> 番茄钟 + 旅行主题的情绪钩子 + 在线排行榜 PK。

## 一句话

每次 25 分钟的专注是一次从**杭州出发的航班**。启动按钮 = 舱门关闭，倒计时 = 飞行中，结束 = 降落在随机目的地。专注时长累计进入全球排行榜，用户之间可以 PK。

## 用户是谁

- **主要用户**：需要专注做事、但对纯工具型番茄钟无感的人。学生、设计师、远程工作者、写作者。
- **次要用户**：把专注当成游戏化习惯追踪的人（打卡、凑成就、和朋友 PK）。

## 问题陈述（今天他们怎么解决，为什么不够好）

- **Forest / 番茄 Todo**：种树很可爱但缺乏**场景叙事**，长期使用会疲劳。
- **Be Focused / Bear Focus**：纯工具型 UI，情绪钩子弱。
- **线下**：手机放远、勿扰模式 —— 没有反馈闭环，容易放弃。

Focus Flight 的差异化赌注：**把 25 分钟包装成一段"真实的旅程"**（随机目的地 + 窗外实景）给用户一个"想完成"的理由，而不只是"不想放弃"的焦虑。

## 成功指标（V0.1 阶段）

因为 V0.1 只用来**验证产品假设 + 技术链路**，量化指标不是重点。合格标准：

- [ ] 能在真机上起飞/降落一次完整的 25 分钟专注
- [ ] 完成后能看到自己出现在排行榜上
- [ ] 人类体验者说"有点好玩，我想再来一次"（≥ 3/5 个试用者）
- [ ] 整条链路（iOS → backend → SQLite → iOS）全部打通

## V0.1 范围（严格限定）

### 做
1. **单一核心界面**：飞机舷窗（SwiftUI 圆角矩形 mask） + 目的地实景 + 倒计时数字
2. **随机航班**：每次启动从后端拉一条，含目的地城市、航班号、背景图集
3. **25 分钟固定倒计时**（本地 Timer，不依赖 backend）
4. **结束上报**：完成的 session 打到 backend
5. **排行榜界面**：Today / All-time 两个 tab，按累计分钟排序 top 50
6. **匿名身份**：首次启动生成 UUID + 让用户输一个昵称（两个字段存本地 UserDefaults）
7. **"景色"用静态图片 + SwiftUI Ken-Burns 动画**（慢平移 + 慢缩放 + 云层视差）

### 不做
- ❌ 可调整时长（固定 25/5 分钟）
- ❌ 短休（Short break）—— 5 分钟到了就弹 alert，不自动续
- ❌ 好友系统（排行榜是全局的）
- ❌ 登录 / 账户恢复 / 换设备同步
- ❌ 推送通知
- ❌ 音效 / BGM（V0.2 再加）
- ❌ 成就系统 / 里程数 / 护照盖章（V0.2）
- ❌ 预渲染 MP4 视频（V0.2 替换静态图）
- ❌ Apple Watch / iPad 专属布局
- ❌ 付费 / 订阅

## 核心用户旅程

```
首次启动
  ↓
输入昵称 → 生成 UUID → POST /users/ensure
  ↓
主界面（舷窗关闭状态）
  ↓
[起飞] → GET /flights/random → 拉到一条航班
  ↓
舷窗打开动画 → 目的地实景（Ken-Burns 动画开始）→ 倒计时 25:00
  ↓
（用户专注 25 分钟，屏幕常亮，背景一直慢慢飘动）
  ↓
降落动画 → POST /sessions → 拉 GET /leaderboard → 显示排名
  ↓
[再来一次] / [查看完整排行榜]
```

## 数据模型（V0.1）

```
users
├── uuid           TEXT PK              -- 客户端生成,首次 POST 时上报
├── nickname       TEXT NOT NULL
├── created_at     TEXT (ISO-8601)
└── last_seen_at   TEXT

sessions
├── id             INTEGER PK AUTOINCREMENT
├── user_uuid      TEXT NOT NULL → users.uuid
├── flight_code    TEXT NOT NULL        -- eg "CZ3123"
├── destination    TEXT NOT NULL        -- eg "Bangkok"
├── started_at     TEXT NOT NULL
├── completed_at   TEXT NOT NULL
└── focus_minutes  INTEGER NOT NULL     -- V0.1 恒为 25

flights  (seed data，不入库，读静态 JSON)
├── code           eg "CZ3123"
├── destination    eg "Bangkok"
├── country        eg "Thailand"
├── duration_h     eg 4 (仅展示,不影响专注时长)
└── image_urls     [url1, url2, url3]   -- 2-4 张高质量城市图
```

**排行榜查询**：
```sql
SELECT u.nickname, u.uuid, SUM(s.focus_minutes) AS total_minutes
FROM sessions s JOIN users u ON u.uuid = s.user_uuid
WHERE [period filter]
GROUP BY u.uuid
ORDER BY total_minutes DESC
LIMIT 50
```

## API 契约（V0.1）

```
POST /users/ensure            { uuid, nickname }            → { uuid, nickname }
GET  /flights/random          ?origin=HGH                    → Flight
POST /sessions                { user_uuid, flight_code,
                                destination, started_at,
                                completed_at, focus_minutes } → Session
GET  /leaderboard             ?period=today|all&limit=50     → Entry[]
```

详细 schema 由 backend 的 Elysia `t.Object()` 定义,并自动出到 `/openapi/json`。

## 开放问题

| # | 问题 | 默认方向 | 待决定 |
|---|---|---|---|
| Q1 | 静态图从哪来？ | V0.1 先用 Unsplash 公开 URL（每个目的地 3 张） | Unsplash API key 要申请；或手动挑图硬编码 |
| Q2 | 专注被中断（切后台 > 60s）算不算完成？ | V0.1 **严格**：离开 app > 10s 就视为失败,不上报 | 未来需要放宽规则 |
| Q3 | 排行榜刷新机制？ | V0.1 pull-to-refresh，不做实时 | |
| Q4 | 反作弊？ | V0.1 不做。单机无所谓 | 联网后很容易刷。V0.2 加 rate limit + 简单签名 |
| Q5 | 时区？ | "today" 以**服务器时区 UTC+8** 为准 | |

## 参考资源（待收集）

- [ ] 10 个目的地城市的 3 张 × 高分辨率图片（建议从 [Unsplash](https://unsplash.com/s/photos/bangkok) 挑）
- [ ] 航班号命名参考（用真实航司前缀 CZ/MU/CA 即可，号段随便编）
- [ ] 杭州→全球的常见航线清单（用于种子数据）

## 相关文档

- 执行计划：`docs/exec-plans/active/2026-04-08-focus-flight-v0.1.md`
- 架构边界：`ARCHITECTURE.md`
- 核心信念：`docs/design-docs/core-beliefs.md`
