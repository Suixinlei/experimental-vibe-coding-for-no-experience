import { Database } from 'bun:sqlite'
import { dirname } from 'node:path'
import { mkdirSync } from 'node:fs'
import { env } from '../env.ts'

// Ensure parent directory exists before opening the file.
mkdirSync(dirname(env.DATABASE_URL), { recursive: true })

export const db = new Database(env.DATABASE_URL, { create: true })

// PRAGMAs that should be set on every connection.
// WAL gives us concurrent reads + a single writer; foreign_keys is off by default in SQLite.
db.exec('PRAGMA journal_mode = WAL;')
db.exec('PRAGMA foreign_keys = ON;')
db.exec('PRAGMA busy_timeout = 5000;')

export type DB = typeof db
