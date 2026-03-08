import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { JWT } from 'npm:google-auth-library@9'
import { createClient } from 'jsr:@supabase/supabase-js@2'

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

    const { request_id, applicant_id } = payload.record

    // Initialize Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Fetch the request details to get the requester_id and title
    const { data: requestData, error: requestError } = await supabase
      .from('help_requests')
      .select('requester_id, title')
      .eq('id', request_id)
      .single()

    if (requestError || !requestData) {
      throw new Error(`Failed to fetch request: ${requestError?.message}`)
    }

    // Don't notify if the applicant is the requester (shouldn't happen, but just in case)
    if (requestData.requester_id === applicant_id) {
      return new Response(JSON.stringify({ success: true, message: "Applicant is requester, no notification sent." }), {
        headers: { "Content-Type": "application/json" },
      })
    }

    // Fetch applicant's name
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .select('name')
      .eq('id', applicant_id)
      .single()

    const applicantName = profileData?.name || 'Someone'

    // FCM setup
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

    // Send to the requester's specific topic matching their userId
    const topic = requestData.requester_id;
    const condition = `'${topic}' in topics`;

    const fcmPayload = {
      message: {
        condition: condition,
        notification: {
          title: 'Interest in Your Request!',
          body: `${applicantName} is interested in helping with ${requestData.title || 'your request'}`,
        },
        data: {
          requestId: String(request_id || ''),
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
