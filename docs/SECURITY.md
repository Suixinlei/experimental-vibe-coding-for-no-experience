# SECURITY.md

> 安全基线。**不可讨价还价**的约束放这里，细化的威胁模型放 `docs/design-docs/security-*.md`。

## 不可讨价还价

- [ ] 不把机密提交进仓库（含 `.env`、密钥、token、客户数据）
- [ ] 所有外部输入在边界处解析（parse, don't validate）
- [ ] 所有 SQL 使用参数化查询或类型安全的查询构建器
- [ ] 依赖项有 lockfile 并定期扫描 CVE
- [ ] CI 中运行 SAST（静态安全扫描）

## 威胁模型

_TODO：首个面向用户的功能落地前必须完成一轮威胁建模并登记到 `docs/design-docs/`。_

## 机密管理

_TODO：选定并记录方案（本地 dotenv / 云 KMS / Vault / ...）_

## 漏洞披露

_TODO：设定联系渠道。_
