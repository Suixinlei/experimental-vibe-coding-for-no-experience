import { Elysia } from 'elysia'
import { FlightService } from './service.ts'
import { FlightModel } from './model.ts'

export const flights = new Elysia({ prefix: '/flights', tags: ['flights'] }).get(
  '/random',
  () => FlightService.random(),
  {
    response: FlightModel.flight,
    detail: {
      summary: 'Pick a random flight from HGH (Hangzhou)',
      description:
        'Returns one randomly selected flight from a static seed list. Call at the start of each focus session to choose a destination.',
    },
  },
)
