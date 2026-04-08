import { status } from 'elysia'
import { FocusRepo } from './repo.ts'
import type {
  User,
  Session,
  LeaderboardEntry,
  LeaderboardPeriod,
  UserEnsureBody,
  SessionCreateBody,
} from './model.ts'

export const FocusService = {
  ensureUser(input: UserEnsureBody): User {
    return FocusRepo.upsertUser(input)
  },

  createSession(input: SessionCreateBody): Session {
    // Boundary checks. Elysia/TypeBox already validated types & bounds;
    // here we enforce cross-field invariants that a schema can't express.

    // 1. user exists
    const user = FocusRepo.findUser(input.user_uuid)
    if (!user) throw status(404, { message: 'unknown user_uuid' })

    // 2. started_at must be before completed_at
    const startedMs = Date.parse(input.started_at)
    const completedMs = Date.parse(input.completed_at)
    if (Number.isNaN(startedMs) || Number.isNaN(completedMs)) {
      throw status(400, { message: 'invalid ISO-8601 timestamp' })
    }
    if (startedMs >= completedMs) {
      throw status(400, { message: 'started_at must be before completed_at' })
    }

    // 3. sanity: (completed - started) should be within 50% of focus_minutes
    //    so clients can't report 25 minutes for a 3-second session.
    const elapsedMin = (completedMs - startedMs) / 60_000
    const ratio = elapsedMin / input.focus_minutes
    if (ratio < 0.5 || ratio > 2) {
      throw status(400, {
        message: `focus_minutes (${input.focus_minutes}) doesn't match elapsed time (${elapsedMin.toFixed(1)}m)`,
      })
    }

    return FocusRepo.insertSession(input)
  },

  getLeaderboard(period: LeaderboardPeriod, limit: number): LeaderboardEntry[] {
    return FocusRepo.leaderboard(period, limit)
  },
}
