// Pure business logic. Deliberately decoupled from Elysia so it can be unit-tested
// without spinning up an HTTP server.

import { db } from '../../db/index.ts'
import type { HealthResponse } from './model.ts'

const APP_VERSION = '0.0.1'
const startedAt = Date.now()

export const HealthService = {
  check(): HealthResponse {
    let reachable = false
    let schemaVersion: string | null = null

    try {
      const row = db
        .query<{ version: string }, []>(
          "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1",
        )
        .get()
      reachable = true
      schemaVersion = row?.version ?? null
    } catch {
      // schema_migrations table missing → migrations haven't run yet.
      reachable = false
    }

    return {
      status: 'ok',
      uptime_seconds: Math.floor((Date.now() - startedAt) / 1000),
      db: { reachable, schema_version: schemaVersion },
      version: APP_VERSION,
    }
  },
}
