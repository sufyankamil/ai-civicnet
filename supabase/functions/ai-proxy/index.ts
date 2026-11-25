import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'

// ai-proxy: the only path from the app to Gemini.
//
// - Verifies the caller's JWT (config.toml also sets verify_jwt = true).
// - Spends one unit of the user's monthly AI quota for metered features
//   (public.consume_ai_quota), answering 402 `quota_exceeded` when exhausted.
// - Calls Gemini with GEMINI_API_KEY, a function secret that never reaches the
//   app binary.
//
// Secrets: `supabase secrets set GEMINI_API_KEY=...`
// (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY are injected.)

const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta'
const CHAT_MODEL = 'gemini-flash-latest'
const EMBED_MODEL = 'gemini-embedding-001'
const EMBED_DIMENSIONS = 768

const MAX_PROMPT_CHARS = 20_000
const MAX_EMBED_CHARS = 8_000
const MAX_HISTORY_TURNS = 20

// metered = counts against the free monthly quota (Pro is unlimited).
// Background matching and helper steps stay unmetered so the marketplace keeps
// working for free users.
const FEATURES: Record<string, { metered: boolean; kind: 'text' | 'embedding' }> = {
  assistant_chat: { metered: true, kind: 'text' },
  voice_task: { metered: true, kind: 'text' },
  briefing: { metered: true, kind: 'text' },
  support: { metered: true, kind: 'text' },
  assistant_search: { metered: false, kind: 'text' },
  categorize: { metered: false, kind: 'text' },
  embedding: { metered: false, kind: 'embedding' },
}

const TASK_TYPES = new Set([
  'RETRIEVAL_QUERY',
  'RETRIEVAL_DOCUMENT',
  'SEMANTIC_SIMILARITY',
  'CLASSIFICATION',
  'CLUSTERING',
])

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Dart's TaskType.retrievalQuery -> RETRIEVAL_QUERY
function toGeminiTaskType(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined
  const converted = value.replace(/([a-z])([A-Z])/g, '$1_$2').toUpperCase()
  return TASK_TYPES.has(converted) ? converted : undefined
}

async function callGemini(path: string, payload: unknown): Promise<Response> {
  return await fetch(`${GEMINI_BASE}/${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': Deno.env.get('GEMINI_API_KEY')!,
    },
    body: JSON.stringify(payload),
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  try {
    if (!Deno.env.get('GEMINI_API_KEY')) {
      console.error('ai-proxy: GEMINI_API_KEY secret is not set')
      return json({ error: 'server_misconfigured' }, 500)
    }

    // 1. Authenticate the caller.
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'unauthorized' }, 401)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: userData, error: userError } = await userClient.auth.getUser()
    if (userError || !userData.user) return json({ error: 'unauthorized' }, 401)
    const userId = userData.user.id

    // 2. Validate the request.
    let body: Record<string, unknown>
    try {
      body = await req.json()
    } catch {
      return json({ error: 'invalid_json' }, 400)
    }

    const featureName = typeof body.feature === 'string' ? body.feature : ''
    const feature = FEATURES[featureName]
    if (!feature) return json({ error: 'unknown_feature' }, 400)

    if (feature.kind === 'text') {
      if (typeof body.prompt !== 'string' || body.prompt.trim() === '') {
        return json({ error: 'prompt_required' }, 400)
      }
      if (body.prompt.length > MAX_PROMPT_CHARS) return json({ error: 'prompt_too_long' }, 413)
    } else {
      if (typeof body.text !== 'string' || body.text.trim() === '') {
        return json({ error: 'text_required' }, 400)
      }
      if (body.text.length > MAX_EMBED_CHARS) return json({ error: 'text_too_long' }, 413)
    }

    // 3. Spend quota for metered features (service role only).
    if (feature.metered) {
      const admin = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
      const { data, error } = await admin.rpc('consume_ai_quota', { p_user_id: userId })
      if (error) {
        console.error('ai-proxy: consume_ai_quota failed', error.message)
        return json({ error: 'quota_check_failed' }, 500)
      }
      const quota = Array.isArray(data) ? data[0] : data
      if (!quota?.allowed) {
        return json(
          { error: 'quota_exceeded', limit: quota?.quota_limit ?? null, resets_at: quota?.resets_at ?? null },
          402,
        )
      }
    }

    // 4. Call Gemini.
    if (feature.kind === 'embedding') {
      const taskType = toGeminiTaskType(body.task_type)
      const res = await callGemini(`models/${EMBED_MODEL}:embedContent`, {
        content: { parts: [{ text: body.text }] },
        ...(taskType ? { taskType } : {}),
      })
      if (!res.ok) {
        console.error('ai-proxy: embed upstream error', res.status)
        return json({ error: 'upstream_error' }, res.status === 503 ? 503 : 502)
      }
      const values: number[] = (await res.json())?.embedding?.values ?? []
      // Same truncation the app always applied, so stored vectors stay compatible.
      return json({ embedding: values.slice(0, EMBED_DIMENSIONS) })
    }

    const history = Array.isArray(body.history) ? body.history.slice(-MAX_HISTORY_TURNS) : []
    const contents = history
      .filter((t: any) => t && (t.role === 'user' || t.role === 'model') && typeof t.text === 'string')
      .map((t: any) => ({ role: t.role, parts: [{ text: String(t.text).slice(0, MAX_PROMPT_CHARS) }] }))
    contents.push({ role: 'user', parts: [{ text: body.prompt as string }] })

    const res = await callGemini(`models/${CHAT_MODEL}:generateContent`, { contents })
    if (!res.ok) {
      console.error('ai-proxy: generate upstream error', res.status)
      return json({ error: 'upstream_error' }, res.status === 503 ? 503 : 502)
    }
    const parts: Array<{ text?: string }> = (await res.json())?.candidates?.[0]?.content?.parts ?? []
    const text = parts.map((p) => p.text ?? '').join('').trim()
    return json({ text })
  } catch (err) {
    console.error('ai-proxy: unexpected error', err)
    return json({ error: 'internal_error' }, 500)
  }
})
