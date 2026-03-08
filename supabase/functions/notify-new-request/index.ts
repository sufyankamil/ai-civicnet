// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { JWT } from 'npm:google-auth-library@9'

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

    const { title, category, id, requester_id } = payload.record

    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountStr) {
      throw new Error("Missing FIREBASE_SERVICE_ACCOUNT environment variable")
    }

    const serviceAccount = JSON.parse(serviceAccountStr)

    const client = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    const { token } = await client.getAccessToken()

    // Send to global topic, but exclude the user who created the request (if they are subscribed to their own ID as a topic)
    const condition = requester_id
      ? `'global_requests' in topics && !('${requester_id}' in topics)`
      : `'global_requests' in topics`;

    const fcmPayload = {
      message: {
        condition: condition,
        notification: {
          title: 'New Help Request!',
          body: `Someone needs help with ${title || 'Something'}`,
        },
        data: {
          requestId: String(id || ''),
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

    const fcmData = await fcmRes.json()

    if (!fcmRes.ok) {
      console.error('FCM Error:', fcmData)
      throw new Error(`FCM API Error: ${JSON.stringify(fcmData)}`)
    }

    return new Response(JSON.stringify({ success: true, fcmResponse: fcmData }), {
      headers: { "Content-Type": "application/json" },
    })

  } catch (error: any) {
    console.error('Function error:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
