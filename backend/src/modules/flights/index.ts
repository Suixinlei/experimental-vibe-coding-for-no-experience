import { Elysia } from 'elysia'
import { cachedImageResponse, withCachedImageURLs } from './image-cache.ts'
import { FlightService } from './service.ts'
import { FlightModel } from './model.ts'

export const flights = new Elysia({ prefix: '/flights', tags: ['flights'] })
  .get(
    '',
    () => FlightService.all(),
    {
      response: FlightModel.flights,
      detail: {
        summary: 'List all focus-flight destinations',
        description:
          'Returns the static destination seed list used by the app for idle-state previews and flight selection.',
      },
    },
  )
  .get(
    '/',
    () => FlightService.all(),
    {
      response: FlightModel.flights,
      detail: {
        summary: 'List all focus-flight destinations',
        description:
          'Returns the static destination seed list used by the app for idle-state previews and flight selection.',
      },
    },
  )
  .get(
    '/random',
    ({ request }) => withCachedImageURLs(FlightService.random(), request.url),
    {
      response: FlightModel.flight,
      detail: {
        summary: 'Pick a random flight from HGH (Hangzhou)',
        description:
          'Returns one randomly selected flight from a static seed list. Call at the start of each focus session to choose a destination.',
      },
    },
  )
  .get('/assets/:filename', async ({ params, set }) => {
    const response = await cachedImageResponse(params.filename)
    if (response) return response

    set.status = 404
    return { message: `cached flight image not found: ${params.filename}` }
  })
