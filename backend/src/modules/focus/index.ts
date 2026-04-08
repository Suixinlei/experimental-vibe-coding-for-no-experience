import { Elysia, t } from 'elysia'
import { FocusService } from './service.ts'
import { FocusModel } from './model.ts'

export const focus = new Elysia({ tags: ['focus'] })
  .post(
    '/users/ensure',
    ({ body }) => FocusService.ensureUser(body),
    {
      body: FocusModel.userEnsureBody,
      response: FocusModel.user,
      detail: {
        summary: 'Upsert anonymous user',
        description:
          'Called on first launch and whenever the nickname changes. Creates the user if missing, otherwise updates nickname + last_seen_at.',
      },
    },
  )
  .post(
    '/sessions',
    ({ body }) => FocusService.createSession(body),
    {
      body: FocusModel.sessionCreateBody,
      response: FocusModel.session,
      detail: {
        summary: 'Report a completed focus session',
        description:
          'Call when the local 25-minute timer hits zero. Server validates elapsed time vs focus_minutes.',
      },
    },
  )
  .get(
    '/leaderboard',
    ({ query }) =>
      FocusService.getLeaderboard(query.period, query.limit),
    {
      query: FocusModel.leaderboardQuery,
      response: t.Array(FocusModel.leaderboardEntry),
      detail: {
        summary: 'Leaderboard by total focus minutes',
        description:
          'period=today uses Asia/Shanghai calendar day. period=all is all-time. Default limit 50.',
      },
    },
  )
