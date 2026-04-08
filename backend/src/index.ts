// Application entry point.
// Composes plugins, mounts modules, starts the HTTP server.

import { Elysia } from 'elysia'
import { openapi } from '@elysiajs/openapi'
import { cors } from '@elysiajs/cors'

import { env } from './env.ts'
import { health } from './modules/health/index.ts'
import { flights } from './modules/flights/index.ts'
import { focus } from './modules/focus/index.ts'

const corsOrigins =
  env.CORS_ORIGINS === '*'
    ? true
    : env.CORS_ORIGINS.split(',').map((s) => s.trim()).filter(Boolean)

export const app = new Elysia()
  .use(cors({ origin: corsOrigins }))
  .use(
    openapi({
      path: '/openapi',
      documentation: {
        info: {
          title: 'backend API',
          version: '0.0.1',
          description:
            'HTTP API for the iOS app. Spec at /openapi/json — feed it to swift-openapi-generator on the iOS side.',
        },
      },
    }),
  )
  .get('/', () => ({ name: 'backend', docs: '/openapi' }))
  .use(health)
  .use(flights)
  .use(focus)
  .onStart(({ server }) => {
    console.log(
      `[backend] listening on http://${server?.hostname}:${server?.port}`,
    )
    console.log(`[backend] OpenAPI UI:  http://${server?.hostname}:${server?.port}/openapi`)
    console.log(`[backend] health:      http://${server?.hostname}:${server?.port}/health`)
  })
  .listen({ port: env.PORT, hostname: env.HOST })

// Exported for end-to-end type sharing if we ever add a TypeScript client.
// (Swift client uses OpenAPI codegen instead — see backend/README.md.)
export type App = typeof app
