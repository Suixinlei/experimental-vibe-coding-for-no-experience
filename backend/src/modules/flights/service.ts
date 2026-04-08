// flights 是静态种子数据。读取一次 → 内存常驻 → 随机选一条。
// 没入库的理由见 decision D5 in exec plan 2026-04-08-focus-flight-v0.1.md。

import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { Value } from '@sinclair/typebox/value'
import { t } from 'elysia'
import { FlightModel, type Flight } from './model.ts'
import { ensureFlightImageCache } from './image-cache.ts'

const here = dirname(fileURLToPath(import.meta.url))
const flightsPath = join(here, 'data', 'flights.json')

// Parse at the boundary: validate the JSON file against our schema once at startup.
// If flights.json is malformed, fail fast here instead of at request time.
const FlightArraySchema = t.Array(FlightModel.flight, { minItems: 1 })

const raw: unknown = JSON.parse(readFileSync(flightsPath, 'utf8'))
const errors = [...Value.Errors(FlightArraySchema, raw)]
if (errors.length > 0) {
  console.error('[flights] invalid flights.json:')
  for (const err of errors) console.error(`  ${err.path}: ${err.message}`)
  process.exit(1)
}

const flights: readonly Flight[] = Object.freeze(raw as Flight[])

console.log(`[flights] loaded ${flights.length} flights from seed`)

export const FlightService = {
  async primeImageCache(): Promise<void> {
    await ensureFlightImageCache(flights)
  },

  random(): Flight {
    const idx = Math.floor(Math.random() * flights.length)
    // noUncheckedIndexedAccess forces us to narrow this — flights.length > 0 guaranteed above.
    const picked = flights[idx]
    if (!picked) throw new Error('unreachable: empty flights')
    return picked
  },

  all(): Flight[] {
    return [...flights]
  },
}
