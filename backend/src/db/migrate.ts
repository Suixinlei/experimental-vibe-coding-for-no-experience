// Minimal forward-only migration runner.
// Each .sql file in ./migrations is applied exactly once, in filename order.
// Filenames must be `NNNN_description.sql`.
//
// Why hand-rolled instead of pulling in drizzle/kysely:
// - bun:sqlite is already native; we don't need a query builder yet
// - keeps the surface area small until we actually need migrations to do more
// - per docs/design-docs/core-beliefs.md #6 (boring is legible)
// When we outgrow this (>1 dev migrating concurrently, branching schemas, etc.),
// promote to drizzle-kit.

import { readdirSync, readFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { db } from './index.ts'

const here = dirname(fileURLToPath(import.meta.url))
const migrationsDir = join(here, 'migrations')

db.exec(`
  CREATE TABLE IF NOT EXISTS schema_migrations (
    version    TEXT PRIMARY KEY,
    applied_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
`)

const applied = new Set(
  db
    .query<{ version: string }, []>('SELECT version FROM schema_migrations')
    .all()
    .map((r) => r.version),
)

const files = readdirSync(migrationsDir)
  .filter((f) => f.endsWith('.sql'))
  .sort()

let ranCount = 0
for (const file of files) {
  const version = file.replace(/\.sql$/, '')
  if (applied.has(version)) continue

  const sql = readFileSync(join(migrationsDir, file), 'utf8')
  console.log(`[migrate] applying ${file}`)

  db.transaction(() => {
    db.exec(sql)
    db.query('INSERT INTO schema_migrations (version) VALUES (?)').run(version)
  })()

  ranCount++
}

if (ranCount === 0) {
  console.log('[migrate] no pending migrations')
} else {
  console.log(`[migrate] applied ${ranCount} migration(s)`)
}
