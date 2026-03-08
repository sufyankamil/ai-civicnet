/* Instructions to Setup the Notification Trigger

Since you are hosting your database on Supabase, the best way to trigger the new `notify-new-request` Edge Function is via the Supabase Dashboard.

1. Go to your Supabase Project Dashboard.
2. Navigate to Database -> Webhooks.
3. Click "Create Webhook".
   - Name: `notify_on_new_request`
   - Table: `help_requests`
   - Events: `Insert`
   - Type: `Supabase Edge Function`
   - Edge Function: `notify-new-request`
   - HTTP Method: `POST`
4. Save the webhook.

Alternatively, if you prefer SQL using `pg_net`:
*/

-- Example SQL (Ensure the pg_net extension is enabled)
create trigger "webhook_notify_new_request"
after insert on "public"."help_requests"
for each row
execute function "supabase_functions"."http_request"(
  'https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/notify-new-request',
  'POST',
  '{"Content-Type":"application/json", "Authorization": "Bearer <YOUR_ANON_KEY>"}',
  '{}',
  '1000'
);

-- ==========================================
-- Notify on Interest (New webhook to add)
-- ==========================================

/*
1. Go to your Supabase Project Dashboard.
2. Navigate to Database -> Webhooks.
3. Click "Create Webhook".
   - Name: `notify_on_interest`
   - Table: `request_applications`
   - Events: `Insert`
   - Type: `Supabase Edge Function`
   - Edge Function: `notify-interest`
   - HTTP Method: `POST`
4. Save the webhook.
*/

-- Example SQL for pg_net:
create trigger "webhook_notify_interest"
after insert on "public"."request_applications"
for each row
execute function "supabase_functions"."http_request"(
  'https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/notify-interest',
  'POST',
  '{"Content-Type":"application/json", "Authorization": "Bearer <YOUR_ANON_KEY>"}',
  '{}',
  '1000'
);
