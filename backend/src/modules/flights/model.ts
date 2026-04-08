import { t, type Static } from 'elysia'

export const FlightModel = {
  flight: t.Object({
    code: t.String({ description: '航班号,例如 CZ3123' }),
    destination: t.String({ description: '目的地城市' }),
    country: t.String(),
    duration_h: t.Number({ description: '真实航班飞行时长(小时),仅展示' }),
    image_urls: t.Array(t.String({ format: 'uri' }), { minItems: 1 }),
  }),
  flights: t.Array(
    t.Object({
      code: t.String({ description: '航班号,例如 CZ3123' }),
      destination: t.String({ description: '目的地城市' }),
      country: t.String(),
      duration_h: t.Number({ description: '真实航班飞行时长(小时),仅展示' }),
      image_urls: t.Array(t.String({ format: 'uri' }), { minItems: 1 }),
    }),
    { minItems: 1 },
  ),
} as const

export type Flight = Static<typeof FlightModel.flight>
