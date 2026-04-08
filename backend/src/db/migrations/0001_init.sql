-- 0001_init.sql
-- 初始 migration。当前没有业务表，仅作为迁移系统的占位。
-- 第一个业务模块落地时新增 0002_<feature>.sql。

-- 用一个 metadata 表证明 migration runner 工作正常 + 留下 schema 版本痕迹。
CREATE TABLE IF NOT EXISTS app_metadata (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT OR IGNORE INTO app_metadata (key, value) VALUES
  ('schema_initialized_at', datetime('now')),
  ('initial_migration', '0001_init');
