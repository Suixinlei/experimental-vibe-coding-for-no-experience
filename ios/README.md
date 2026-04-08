# ios/

iOS 原生 App。**Xcode 工程尚未生成** —— 等命令行 `xcode-select` 切换到完整 Xcode 后再生成。

## 下一步（按顺序）

### 0. 把命令行工具切换到完整 Xcode（需要 sudo，由人类执行）

在 Claude Code 输入框里用 `!` 前缀直接跑：

```
! sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
! sudo xcodebuild -license accept
! xcodebuild -version
! xcrun simctl list devices available | grep iPhone
```

四条都成功后，agent 才能继续生成工程。

### 1. 生成 Xcode 工程（agent 来做）

技术选型已定：
- **语言**：Swift 6
- **UI**：SwiftUI（首选，比 UIKit 对 agent 友好得多 —— 声明式、状态可观察、预览即所见即所得）
- **最低支持**：iOS 17（需要 SwiftUI 的 `Observable` 宏 + Swift 并发的现代 API）
- **架构**：MV（Model-View），不上 VIPER/Clean，避免过度抽象
- **网络**：从 backend 的 `/openapi/json` 用 [`swift-openapi-generator`](https://github.com/apple/swift-openapi-generator) codegen Swift 客户端，**不手写** URLSession 调用
- **本地持久化**：SwiftData（如确需）。注意 backend 才是真理之源 —— iOS 端的本地存储仅作为缓存
- **依赖管理**：Swift Package Manager（**不用** CocoaPods）

工程生成方式（待 Xcode 装好后）：
- 用 Xcode GUI: File → New → Project → iOS → App
  - Product Name: `App`
  - Interface: SwiftUI
  - Language: Swift
  - Storage: None（首版不上 SwiftData，等业务需要再加）
  - 取消 "Include Tests"（首版用 SwiftPM 测试，不用 XCTest 模板）
- 工程位置：`ios/App/`

### 2. 接 swift-openapi-generator

- 在 Xcode 里 File → Add Package Dependencies → `https://github.com/apple/swift-openapi-generator`
- 同时加 `swift-openapi-runtime` 和 `swift-openapi-urlsession`
- 在工程根加 `openapi.yaml`（用 `curl http://127.0.0.1:3000/openapi/json | yq -P > openapi.yaml` 生成）
- 配 `openapi-generator-config.yaml`

### 3. 实现首个端到端调用

从 SwiftUI 的入口 View 调一次 `/health`，把结果显示出来。这就证明了 client ↔ server ↔ db 全链路通。

## 与 backend 的契约

- backend 跑在 `http://127.0.0.1:3000`（dev）
- iOS 端**不写** `URL(string:)` + `URLSession` 这种手摇代码
- 任何 API 改动 → backend 改 → 重新拉 OpenAPI → iOS 重新 codegen
- 模拟器访问 host 用 `http://127.0.0.1:3000` 即可（模拟器和 host 共享网络）；真机走局域网 IP

## 不要做的事

- ❌ 不要用 CocoaPods（SwiftPM 已经够用了，少一层依赖管理）
- ❌ 不要手写 URLSession 数据层（破坏与 backend 的契约同步）
- ❌ 不要把 secret 写进 Info.plist；用环境注入或 Keychain
- ❌ 不要把 SwiftData / Core Data 当主存储（backend 才是事实来源）
