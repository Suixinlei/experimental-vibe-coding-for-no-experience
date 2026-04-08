import { t, type Static } from 'elysia'

export const FocusModel = {
  // ─── requests ────────────────────────────────────────────
  userEnsureBody: t.Object({
    uuid: t.String({
      minLength: 8,
      maxLength: 64,
      description: 'Client-generated device UUID. Stable per install.',
    }),
    nickname: t.String({ minLength: 1, maxLength: 32 }),
  }),

  sessionCreateBody: t.Object({
    user_uuid: t.String({ minLength: 8, maxLength: 64 }),
    flight_code: t.String({ minLength: 1, maxLength: 16 }),
    destination: t.String({ minLength: 1, maxLength: 64 }),
    started_at: t.String({ format: 'date-time' }),
    completed_at: t.String({ format: 'date-time' }),
    focus_minutes: t.Integer({ minimum: 1, maximum: 240 }),
  }),

  // ─── responses ───────────────────────────────────────────
  user: t.Object({
    uuid: t.String(),
    nickname: t.String(),
    created_at: t.String(),
    last_seen_at: t.String(),
  }),

  session: t.Object({
    id: t.Integer(),
    user_uuid: t.String(),
    flight_code: t.String(),
    destination: t.String(),
    started_at: t.String(),
    completed_at: t.String(),
    focus_minutes: t.Integer(),
  }),

  leaderboardEntry: t.Object({
    rank: t.Integer(),
    user_uuid: t.String(),
    nickname: t.String(),
    total_minutes: t.Integer(),
    session_count: t.Integer(),
  }),

  leaderboardQuery: t.Object({
    period: t.Union([t.Literal('today'), t.Literal('all')], { default: 'today' }),
    limit: t.Integer({ default: 50, minimum: 1, maximum: 200 }),
  }),
} as const

export type UserEnsureBody = Static<typeof FocusModel.userEnsureBody>
export type SessionCreateBody = Static<typeof FocusModel.sessionCreateBody>
export type User = Static<typeof FocusModel.user>
export type Session = Static<typeof FocusModel.session>
export type LeaderboardEntry = Static<typeof FocusModel.leaderboardEntry>
export type LeaderboardPeriod = 'today' | 'all'
