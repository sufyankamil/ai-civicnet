# Security Hardening — Apply Steps

Run these after deploying the app build that includes per-conversation chat encryption.

## 1. Apply SQL

1. Open Supabase Dashboard → **SQL Editor** → New query.
2. Paste and run [`sql_scripts/security_hardening.sql`](security_hardening.sql).
3. Confirm no errors. Re-running the script is safe (idempotent drops/creates).

This creates:

- `profiles.public_wrap_key`
- `conversation_keys` + RLS
- `profiles_safe` view (no lat/lng/role/report_count)
- RPCs: `get_public_wrap_key`, `get_active_neighbors`, `conversation_has_keys`, `conversation_key_user_ids`, `is_guild_member`
- Tightened RLS on help_requests, comments, polls, badges, guilds, assets
- Private `chat-attachments` storage bucket + participant path policies

## 2. Redeploy Edge Function

```bash
supabase functions deploy notify-new-message
```

Push notifications no longer decrypt message bodies (generic “New message” / “Sent an image”).

You can remove the `ENCRYPTION_KEY` secret from the Edge Function environment after deploy. Keep `ENCRYPTION_KEY` in the **client** `.env` only during the legacy dual-read window so old ciphertext still decrypts in-app.

## 3. Client secrets

| Secret | Client? | Notes |
|--------|---------|--------|
| `SUPABASE_ANON_KEY` | Yes | Expected; protected by RLS |
| `ENCRYPTION_KEY` | **No** | Removed — chat uses per-conversation keys only |
| Service role key | **Never** | Server/Edge only |

Do not put `ENCRYPTION_KEY` back in `.env` or app assets. Old messages encrypted with the former global key will not decrypt; new messages use per-conversation keys.

## 4. Smoke checks

- Sign in → profile row gets `public_wrap_key`.
- Start a DM → `conversation_keys` has wrapped rows; `messages.content` is opaque ciphertext.
- Push shows sender name + generic body.
- Anon REST `GET /rest/v1/profiles` and `help_requests` should not return rows.
- Other-user profile fetch via `profiles_safe` has no `lat`/`lng`.
