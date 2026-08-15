import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { JWT } from 'npm:google-auth-library@9'

interface HolidayNotificationPayload {
  countryCode?: string
  title?: string
  body?: string
  eventId?: string
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

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
    const countryCode = (payload.countryCode ?? 'IN').toUpperCase()
    if (!/^[A-Z]{2}$/.test(countryCode)) {
      return json({ error: 'countryCode must be a two-letter ISO country code' }, 400)
    }

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

    const eventId = payload.eventId ?? `holiday_${countryCode}_${new Date().toISOString().slice(0, 10)}`
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            topic: `country_${countryCode}`,
            notification: {
              title: payload.title ?? 'Happy Independence Day! 🇮🇳',
              body: payload.body ?? 'स्वतंत्रता दिवस की शुभकामनाएँ',
            },
            data: {
              type: 'seasonal_greeting',
              event_id: eventId,
              country_code: countryCode,
            },
          },
        }),
      },
    )
    const fcmData = await fcmResponse.json()
    if (!fcmResponse.ok) {
      console.error('FCM error:', fcmData)
      return json({ error: 'FCM delivery failed', detail: fcmData }, 502)
    }

    return json({ success: true, topic: `country_${countryCode}`, eventId, fcm: fcmData })
  } catch (error) {
    console.error('Holiday notification error:', error)
    return json({ error: String(error) }, 500)
  }
})
