// Sends the push for an Emergency SOS (issue #108) to people near it.
//
// Triggered by a Database Webhook on INSERT into public.help_requests (see
// sql_scripts/sos_schema.sql for setup). Unlike notify-new-request, which goes
// to every user, this only reaches device tokens within SOS_RADIUS_M of the
// SOS, never the requester and never anyone with a block in either direction.
//
// Secrets: FIREBASE_SERVICE_ACCOUNT, NOTIFY_SOS_SECRET (also sent by the webhook
// as the x-webhook-secret header). Optional: SOS_RADIUS_M (default 2000).
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

const RADIUS_M = Number(Deno.env.get('SOS_RADIUS_M') ?? '2000')
const CONCURRENCY = 20

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  try {
    const secret = Deno.env.get('NOTIFY_SOS_SECRET')
    if (!secret || req.headers.get('x-webhook-secret') !== secret) {
      return json({ error: 'forbidden' }, 403)
    }

    const payload = await req.json()
    if (payload.type !== 'INSERT' || payload.table !== 'help_requests') {
      return json({ error: 'Only help_requests INSERT is supported' }, 400)
    }
    const record = payload.record
    if (!record?.is_sos) return json({ skipped: 'not an SOS' })
    const requestId = record.id

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { persistSession: false } },
    )

    // Claim the SOS so a repeated webhook delivery cannot send the push twice.
    const { data: claimed, error: claimError } = await supabase
      .from('help_requests')
      .update({ sos_notified_at: new Date().toISOString() })
      .eq('id', requestId)
      .eq('is_sos', true)
      .is('sos_notified_at', null)
      .select('id')
      .maybeSingle()
    if (claimError) throw claimError
    if (!claimed) return json({ skipped: 'already notified' })

    const { data: tokens, error: tokenError } = await supabase.rpc(
      'sos_recipient_tokens',
      { p_request_id: requestId, p_radius_m: RADIUS_M },
    )
    if (tokenError) throw tokenError

    const list: { token: string; platform: string }[] = tokens ?? []
    if (list.length === 0) {
      await supabase.from('help_requests').update({ sos_alert_count: 0 }).eq('id', requestId)
      return json({ alerted: 0, total: 0 })
    }

    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountStr) throw new Error('Missing FIREBASE_SERVICE_ACCOUNT environment variable')
    const serviceAccount = JSON.parse(serviceAccountStr)
    const client = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const { token: accessToken } = await client.getAccessToken()
    const endpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

    let sent = 0
    let failed = 0
    const dead: string[] = []

    const sendOne = async (deviceToken: string) => {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: deviceToken,
            notification: {
              title: 'SOS: someone nearby needs help',
              body: 'Tap to see where and offer help.',
            },
            data: {
              requestId: String(requestId),
              type: 'sos',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: { priority: 'HIGH' },
            apns: {
              headers: { 'apns-priority': '10' },
              payload: { aps: { sound: 'default', 'interruption-level': 'time-sensitive' } },
            },
          },
        }),
      })
      if (res.ok) {
        sent++
        return
      }
      failed++
      const body = await res.json().catch(() => ({}))
      const code = body?.error?.details?.[0]?.errorCode ?? body?.error?.status
      if (code === 'UNREGISTERED' || code === 'NOT_FOUND') dead.push(deviceToken)
      else console.error('FCM error', res.status, code)
    }

    // Small worker pool: FCM v1 has no multicast.
    const queue = list.map((t) => t.token)
    await Promise.all(
      Array.from({ length: Math.min(CONCURRENCY, queue.length) }, async () => {
        while (queue.length > 0) {
          const next = queue.shift()
          if (next) await sendOne(next)
        }
      }),
    )

    if (dead.length > 0) await supabase.from('device_tokens').delete().in('token', dead)
    await supabase.from('help_requests').update({ sos_alert_count: sent }).eq('id', requestId)

    return json({ alerted: sent, failed, total: list.length })
  } catch (error: any) {
    console.error('notify-sos error:', error)
    return json({ error: error.message }, 500)
  }
})
