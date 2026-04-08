import { t } from 'elysia'
import { Value } from '@sinclair/typebox/value'

// Parse, don't validate. Environment variables are external input —
// they get turned into a strongly-typed object exactly once, here.
const EnvSchema = t.Object({
  PORT: t.Number({ default: 3000 }),
  HOST: t.String({ default: '127.0.0.1' }),
  DATABASE_URL: t.String({ default: './data/app.db' }),
  CORS_ORIGINS: t.String({ default: '*' }),
  LOG_LEVEL: t.Union(
    [t.Literal('debug'), t.Literal('info'), t.Literal('warn'), t.Literal('error')],
    { default: 'info' },
  ),
})

const raw = {
  PORT: process.env.PORT ? Number(process.env.PORT) : undefined,
  HOST: process.env.HOST,
  DATABASE_URL: process.env.DATABASE_URL,
  CORS_ORIGINS: process.env.CORS_ORIGINS,
  LOG_LEVEL: process.env.LOG_LEVEL,
}

// Strip undefined so defaults kick in, then Cast to apply defaults + coerce types.
const cleaned = Object.fromEntries(
  Object.entries(raw).filter(([, v]) => v !== undefined),
)

const parsed = Value.Cast(EnvSchema, cleaned)
const errors = [...Value.Errors(EnvSchema, parsed)]

if (errors.length > 0) {
  console.error('Invalid environment configuration:')
  for (const err of errors) console.error(`  ${err.path}: ${err.message}`)
  process.exit(1)
}

export const env = parsed
export type Env = typeof env
