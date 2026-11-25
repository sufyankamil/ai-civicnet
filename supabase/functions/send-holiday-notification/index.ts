import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { JWT } from 'npm:google-auth-library@9'
import { holidaysToday } from './holidays.ts'

// Two ways to call this function (both authenticated by the cron secret):
//
//  1. Explicit greeting, used by the India Independence Day cron job:
//       { "countryCode": "IN", "title": "...", "body": "...", "eventId": "..." }
//
//  2. Daily mode, used by the GCC cron jobs:
//       { "daily": true, "countryCodes": ["AE", "OM"] }
//     The function finds the holidays that are today in each country's own
//     time zone (see holidays.ts) and sends each one to that country's topic.
//     On an ordinary day it sends nothing.

interface HolidayNotificationPayload {
  countryCode?: string
  title?: string
  body?: string
  eventId?: string
  daily?: boolean
  countryCodes?: string[]
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

const isCountryCode = (value: unknown): value is string =>
  typeof value === 'string' && /^[A-Z]{2}$/.test(value)

async function getFcmAccess(): Promise<{ token: string; projectId: string }> {
  const serviceAccountString = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!serviceAccountString) throw new Error('Missing FIREBASE_SERVICE_ACCOUNT')
  const serviceAccount = JSON.parse(serviceAccountString)

  const authClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })
  const { token } = await authClient.getAccessToken()
  if (!token) throw new Error('Could not obtain an FCM access token')
  return { token, projectId: serviceAccount.project_id }
}

async function sendToCountryTopic(
  access: { token: string; projectId: string },
  countryCode: string,
  title: string,
  body: string,
  eventId: string,
) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${access.projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${access.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          topic: `country_${countryCode}`,
          notification: { title, body },
          data: {
            type: 'seasonal_greeting',
            event_id: eventId,
            country_code: countryCode,
          },
        },
      }),
    },
  )
  const data = await response.json()
  return { ok: response.ok, data }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  // This function is called by the Supabase cron job. Do not expose it to app clients.
  const schedulerSecret = Deno.env.get('HOLIDAY_NOTIFICATION_SECRET')
  if (!schedulerSecret ||
      req.headers.get('x-holiday-notification-secret') !== schedulerSecret) {
    return json({ error: 'Unauthorized' }, 401)
  }

  try {
    const payload = await req.json().catch(() => ({})) as HolidayNotificationPayload

    // Daily mode: send whatever holidays fall today for the given countries.
    if (payload.daily) {
      const codes = (payload.countryCodes ?? []).map((c) => String(c).toUpperCase())
      if (codes.length === 0 || !codes.every(isCountryCode)) {
        return json({ error: 'countryCodes must be a non-empty list of two-letter ISO country codes' }, 400)
      }

      const now = new Date()
      const holidays = holidaysToday(now, codes)
      if (holidays.length === 0) return json({ success: true, sent: [] })

      const access = await getFcmAccess()
      const year = now.getUTCFullYear()
      const sent: string[] = []
      const failed: { eventId: string; detail: unknown }[] = []

      for (const holiday of holidays) {
        const eventId = `${holiday.eventId}_${year}`
        const result = await sendToCountryTopic(access, holiday.countryCode, holiday.title, holiday.body, eventId)
        if (result.ok) {
          sent.push(eventId)
        } else {
          console.error('FCM error:', holiday.eventId, result.data)
          failed.push({ eventId, detail: result.data })
        }
      }

      return json({ success: failed.length === 0, sent, failed }, failed.length === 0 ? 200 : 502)
    }

    // Explicit greeting (India Independence Day cron job).
    const countryCode = (payload.countryCode ?? 'IN').toUpperCase()
    if (!isCountryCode(countryCode)) {
      return json({ error: 'countryCode must be a two-letter ISO country code' }, 400)
    }

    const access = await getFcmAccess()
    const eventId = payload.eventId ?? `holiday_${countryCode}_${new Date().toISOString().slice(0, 10)}`
    const result = await sendToCountryTopic(
      access,
      countryCode,
      payload.title ?? 'Happy Independence Day! 🇮🇳',
      payload.body ?? 'स्वतंत्रता दिवस की शुभकामनाएँ',
      eventId,
    )
    if (!result.ok) {
      console.error('FCM error:', result.data)
      return json({ error: 'FCM delivery failed', detail: result.data }, 502)
    }

    return json({ success: true, topic: `country_${countryCode}`, eventId, fcm: result.data })
  } catch (error) {
    console.error('Holiday notification error:', error)
    return json({ error: String(error) }, 500)
  }
})
