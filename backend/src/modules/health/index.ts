// HTTP adapter for the health module.
// Per Elysia best practice: controller only handles routing + validation;
// real logic lives in service.ts.

import { Elysia } from 'elysia'
import { HealthService } from './service.ts'
import { HealthModel } from './model.ts'

export const health = new Elysia({ prefix: '/health', tags: ['health'] }).get(
  '/',
  () => HealthService.check(),
  {
    response: HealthModel.response,
    detail: {
      summary: 'Liveness + DB reachability probe',
      description:
        'Returns process uptime, current schema version, and whether the SQLite file is reachable. Safe to call from monitoring or from the iOS client at launch.',
    },
  },
)
