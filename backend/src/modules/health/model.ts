import { t, type Static } from 'elysia'

export const HealthModel = {
  response: t.Object({
    status: t.Literal('ok'),
    uptime_seconds: t.Number(),
    db: t.Object({
      reachable: t.Boolean(),
      schema_version: t.Union([t.String(), t.Null()]),
    }),
    version: t.String(),
  }),
} as const

export type HealthResponse = Static<typeof HealthModel.response>
