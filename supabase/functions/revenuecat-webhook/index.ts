import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { mapEvent } from './mapping.ts'

// revenuecat-webhook: keeps public.subscriptions in sync with RevenueCat so
// consume_ai_quota (and the ai-proxy) know who is Pro.
//
// RevenueCat dashboard -> Integrations -> Webhooks:
//   URL:                  https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
//   Authorization header: Bearer <REVENUECAT_WEBHOOK_SECRET>
// Secret: `supabase secrets set REVENUECAT_WEBHOOK_SECRET=<long random string>`
//
// verify_jwt is false (RevenueCat has no Supabase JWT); the shared secret is
// the authentication.

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

// Compare without bailing out on the first differing character.
function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder()
  const x = enc.encode(a)
  const y = enc.encode(b)
  let diff = x.length ^ y.length
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    diff |= (x[i] ?? 0) ^ (y[i] ?? 0)
  }
  return diff === 0
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  const secret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
  if (!secret) {
    console.error('revenuecat-webhook: REVENUECAT_WEBHOOK_SECRET is not set')
    return json({ error: 'server_misconfigured' }, 500)
  }
  const provided = req.headers.get('Authorization') ?? ''
  if (!safeEqual(provided, `Bearer ${secret}`)) return json({ error: 'unauthorized' }, 401)

  try {
    let payload: { event?: Record<string, unknown> }
    try {
      payload = await req.json()
    } catch {
      return json({ error: 'invalid_json' }, 400)
    }

    const result = mapEvent((payload.event ?? {}) as Parameters<typeof mapEvent>[0])
    if (result.action === 'ignore') return json({ ok: true, ignored: result.reason })

    const u = result.update
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const { data, error } = await admin.rpc('apply_subscription_event', {
      p_user_id: u.user_id,
      p_entitlement: u.entitlement,
      p_status: u.status,
      p_trial_ends_at: u.trial_ends_at,
      p_current_period_end: u.current_period_end,
      p_source: u.source,
      p_last_event_ms: u.last_event_ms,
    })

    if (error) {
      // 23503 = foreign key violation: the user no longer exists. Retrying
      // can never succeed, so acknowledge it.
      if (error.code === '23503') return json({ ok: true, ignored: 'unknown_user' })
      console.error('revenuecat-webhook: apply_subscription_event failed', error.message)
      // A non-2xx makes RevenueCat retry the delivery.
      return json({ error: 'db_error' }, 500)
    }

    return json({ ok: true, applied: data === true })
  } catch (err) {
    console.error('revenuecat-webhook: unexpected error', err)
    return json({ error: 'internal_error' }, 500)
  }
})
