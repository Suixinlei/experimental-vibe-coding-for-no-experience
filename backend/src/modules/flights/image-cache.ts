import { existsSync, mkdirSync } from 'node:fs'
import { dirname, extname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import type { Flight } from './model.ts'

const here = dirname(fileURLToPath(import.meta.url))
const cacheDir = join(here, '..', '..', '..', 'data', 'flight-images')

function slugify(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function inferExtension(url: string): string {
  const pathname = new URL(url).pathname
  const ext = extname(pathname).toLowerCase()
  return ext === '.png' ? '.png' : '.jpg'
}

function imageFilename(flight: Flight, index: number): string {
  return `${slugify(flight.destination)}-${index + 1}${inferExtension(flight.image_urls[index] ?? '')}`
}

function imagePath(filename: string): string {
  return join(cacheDir, filename)
}

async function downloadImage(url: string, targetPath: string): Promise<void> {
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`failed to download ${url}: ${response.status} ${response.statusText}`)
  }

  const bytes = await response.arrayBuffer()
  await Bun.write(targetPath, bytes)
}

export async function ensureFlightImageCache(flights: readonly Flight[]): Promise<void> {
  mkdirSync(cacheDir, { recursive: true })

  for (const flight of flights) {
    for (let index = 0; index < flight.image_urls.length; index += 1) {
      const filename = imageFilename(flight, index)
      const targetPath = imagePath(filename)
      if (existsSync(targetPath)) continue
      try {
        await downloadImage(flight.image_urls[index]!, targetPath)
      } catch (error) {
        console.warn(`[flights] image cache skip ${flight.destination} #${index + 1}: ${String(error)}`)
      }
    }
  }
}

export function withCachedImageURLs(flight: Flight, requestURL: string): Flight {
  const baseURL = new URL(requestURL)
  const cachedURLs = flight.image_urls
    .map((_, index) => imageFilename(flight, index))
    .filter((filename) => existsSync(imagePath(filename)))
    .map((filename) => new URL(`/flights/assets/${filename}`, baseURL).toString())

  return {
    ...flight,
    image_urls: cachedURLs.length > 0 ? cachedURLs : flight.image_urls,
  }
}

export async function cachedImageResponse(filename: string): Promise<Response | null> {
  if (!/^[a-z0-9-]+\.(jpg|png)$/.test(filename)) return null

  const file = Bun.file(imagePath(filename))
  if (!(await file.exists())) return null

  return new Response(file, {
    headers: {
      'Cache-Control': 'public, max-age=86400',
      'Content-Type': file.type || 'image/jpeg',
    },
  })
}
