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

async function decryptContent(encryptedBase64: string, keyString: string): Promise<string> {
  try {
    const binaryDerivation = new TextEncoder().encode(keyString);
    // Ensure key is exactly 32 bytes for AES-256
    let keyBytes = new Uint8Array(32).fill(48); // Pad with '0' (ASCII 48)
    if (binaryDerivation.length >= 32) {
      keyBytes.set(binaryDerivation.slice(0, 32));
    } else {
      keyBytes.set(binaryDerivation);
    }

    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyBytes,
      { name: "AES-CBC" },
      false,
      ["decrypt"]
    );

    const decoded = Uint8Array.from(atob(encryptedBase64), c => c.charCodeAt(0));
    if (decoded.length < 16) return encryptedBase64;

    const iv = decoded.slice(0, 16);
    const ciphertext = decoded.slice(16);

    const decryptedBuffer = await crypto.subtle.decrypt(
      { name: "AES-CBC", iv: iv },
      cryptoKey,
      ciphertext
    );

    return new TextDecoder().decode(decryptedBuffer);
  } catch (e) {
    console.error('Decryption failed:', e);
    return "[Encrypted Message]";
  }
}

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()

    if (payload.type !== 'INSERT') {
      return new Response(JSON.stringify({ error: "Only INSERT is supported" }), { status: 400 })
    }

    const { conversation_id, sender_id, content, message_type } = payload.record

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
    const { data: senderData, error: senderError } = await supabase
      .from('profiles')
      .select('name')
      .eq('id', sender_id)
      .single()

    const senderName = senderData?.name || 'Someone'

    // 3. Decrypt content if it's text
    let displayContent = "Sent a message";
    if (message_type === 'text' || !message_type) {
      const encryptionKey = Deno.env.get('ENCRYPTION_KEY');
      if (encryptionKey) {
        displayContent = await decryptContent(content, encryptionKey);
      } else {
        displayContent = "New message received";
      }
    } else if (message_type === 'image') {
      displayContent = "📷 Sent an image";
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
          body: displayContent.length > 100 ? displayContent.substring(0, 97) + '...' : displayContent,
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

    const fcmData = await fcmRes.json()
    return new Response(JSON.stringify({ success: true, fcmResponse: fcmData }), {
      headers: { "Content-Type": "application/json" },
    })

  } catch (error: any) {
    console.error('Function error:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
