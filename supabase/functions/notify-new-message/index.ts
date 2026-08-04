import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { JWT } from 'npm:google-auth-library@9'
import { createClient } from '@supabase/supabase-js'

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: any
  schema: string
  old_record: null | any
}

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()

    if (payload.type !== 'INSERT') {
      return new Response(JSON.stringify({ error: "Only INSERT is supported" }), { status: 400 })
    }

    const { conversation_id, sender_id, message_type } = payload.record

    // Initialize Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 1. Fetch conversation to find the recipient
    const { data: conversationData, error: convError } = await supabase
      .from('conversations')
      .select('participant_ids')
      .eq('id', conversation_id)
      .single()

    if (convError || !conversationData) {
      throw new Error(`Failed to fetch conversation: ${convError?.message}`)
    }

    const recipientId = conversationData.participant_ids.find((id: string) => id !== sender_id)
    if (!recipientId) {
      return new Response(JSON.stringify({ success: true, message: "No recipient found" }))
    }

    // 2. Fetch sender's name
    const { data: senderData } = await supabase
      .from('profiles')
      .select('name')
      .eq('id', sender_id)
      .single()

    const senderName = senderData?.name || 'Someone'

    // 3. Generic body only — message content is E2E encrypted; never decrypt server-side.
    let displayContent = 'New message'
    if (message_type === 'image') {
      displayContent = 'Sent an image'
    } else if (message_type === 'audio') {
      displayContent = 'Sent an audio message'
    }

    // 4. FCM setup
    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountStr) throw new Error("Missing FIREBASE_SERVICE_ACCOUNT")
    const serviceAccount = JSON.parse(serviceAccountStr)

    const authClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    const { token } = await authClient.getAccessToken()
    const topic = `user_${recipientId}`.replace(/-/g, '_');

    const fcmPayload = {
      message: {
        topic: topic,
        notification: {
          title: senderName,
          body: displayContent,
        },
        data: {
          conversationId: String(conversation_id || ''),
          senderId: String(sender_id || ''),
          senderName: senderName,
          type: 'chat',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        }
      }
    }

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      }
    )

    const fcmJson = await fcmRes.json()
    if (!fcmRes.ok) {
      console.error('FCM error:', fcmJson)
      throw new Error(`FCM send failed: ${JSON.stringify(fcmJson)}`)
    }

    return new Response(JSON.stringify({ success: true, fcm: fcmJson }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error(err)
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})
