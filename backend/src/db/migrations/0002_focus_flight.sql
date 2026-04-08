-- 0002_focus_flight.sql
-- Focus Flight V0.1: 用户 + session。
-- flights 数据不入库,由 src/modules/flights/data/flights.json 提供。

CREATE TABLE users (
  uuid         TEXT PRIMARY KEY,
  nickname     TEXT NOT NULL CHECK (length(nickname) BETWEEN 1 AND 32),
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  last_seen_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE sessions (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  user_uuid     TEXT NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
  flight_code   TEXT NOT NULL,
  destination   TEXT NOT NULL,
  started_at    TEXT NOT NULL,            -- ISO-8601 UTC
  completed_at  TEXT NOT NULL,            -- ISO-8601 UTC
  focus_minutes INTEGER NOT NULL CHECK (focus_minutes > 0)
);

CREATE INDEX idx_sessions_user         ON sessions(user_uuid);
CREATE INDEX idx_sessions_completed_at ON sessions(completed_at);
