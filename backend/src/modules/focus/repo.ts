// All SQL for the focus module lives here. Service layer calls into this —
// never writes SQL directly. See decision D6 in the exec plan.

import { db } from '../../db/index.ts'
import type {
  User,
  Session,
  LeaderboardEntry,
  LeaderboardPeriod,
  UserEnsureBody,
  SessionCreateBody,
} from './model.ts'

// Row types — what bun:sqlite returns. Converted to the public types in the service layer.
type UserRow = {
  uuid: string
  nickname: string
  created_at: string
  last_seen_at: string
}

type SessionRow = {
  id: number
  user_uuid: string
  flight_code: string
  destination: string
  started_at: string
  completed_at: string
  focus_minutes: number
}

type LeaderboardRow = {
  user_uuid: string
  nickname: string
  total_minutes: number
  session_count: number
}

export const FocusRepo = {
  upsertUser(input: UserEnsureBody): User {
    // INSERT ... ON CONFLICT updates nickname + last_seen_at on every call.
    // Bumping last_seen_at is how we track "active users" cheaply.
    const row = db
      .query<UserRow, [string, string]>(
        `INSERT INTO users (uuid, nickname)
         VALUES (?1, ?2)
         ON CONFLICT(uuid) DO UPDATE SET
           nickname     = excluded.nickname,
           last_seen_at = datetime('now')
         RETURNING uuid, nickname, created_at, last_seen_at`,
      )
      .get(input.uuid, input.nickname)

    if (!row) throw new Error('upsertUser: no row returned')
    return row
  },

  findUser(uuid: string): User | null {
    return (
      db
        .query<UserRow, [string]>(
          'SELECT uuid, nickname, created_at, last_seen_at FROM users WHERE uuid = ?1',
        )
        .get(uuid) ?? null
    )
  },

  insertSession(input: SessionCreateBody): Session {
    const row = db
      .query<SessionRow, [string, string, string, string, string, number]>(
        `INSERT INTO sessions
           (user_uuid, flight_code, destination, started_at, completed_at, focus_minutes)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)
         RETURNING id, user_uuid, flight_code, destination, started_at, completed_at, focus_minutes`,
      )
      .get(
        input.user_uuid,
        input.flight_code,
        input.destination,
        input.started_at,
        input.completed_at,
        input.focus_minutes,
      )

    if (!row) throw new Error('insertSession: no row returned')
    return row
  },

  leaderboard(period: LeaderboardPeriod, limit: number): LeaderboardEntry[] {
    // "today" is defined as UTC+8 (Asia/Shanghai) — see Q5 in product spec.
    // SQLite's datetime('now','+8 hours') gives us the Shanghai time; we compare against
    // the start of that day converted back to UTC for the stored ISO-8601 values.
    const rows =
      period === 'today'
        ? db
            .query<LeaderboardRow, [number]>(
              `SELECT
                 s.user_uuid,
                 u.nickname,
                 SUM(s.focus_minutes) AS total_minutes,
                 COUNT(*)             AS session_count
               FROM sessions s
               JOIN users u ON u.uuid = s.user_uuid
               WHERE s.completed_at >= datetime('now', '+8 hours', 'start of day', '-8 hours')
               GROUP BY s.user_uuid
               ORDER BY total_minutes DESC
               LIMIT ?1`,
            )
            .all(limit)
        : db
            .query<LeaderboardRow, [number]>(
              `SELECT
                 s.user_uuid,
                 u.nickname,
                 SUM(s.focus_minutes) AS total_minutes,
                 COUNT(*)             AS session_count
               FROM sessions s
               JOIN users u ON u.uuid = s.user_uuid
               GROUP BY s.user_uuid
               ORDER BY total_minutes DESC
               LIMIT ?1`,
            )
            .all(limit)

    return rows.map((r, i) => ({
      rank: i + 1,
      user_uuid: r.user_uuid,
      nickname: r.nickname,
      total_minutes: r.total_minutes,
      session_count: r.session_count,
    }))
  },
}
