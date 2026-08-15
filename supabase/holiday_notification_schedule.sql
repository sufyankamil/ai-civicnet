-- One-time setup for the Independence Day push notification.
-- Replace <PROJECT_REF> and <A_LONG_RANDOM_SECRET> before running.
-- The cron expression is 03:30 UTC = 09:00 Asia/Kolkata, every August 15.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

-- Store the secret in Supabase Vault; never commit the secret to source control.
select vault.create_secret(
  '<A_LONG_RANDOM_SECRET>',
  'holiday_notification_secret',
  'Secret used by the Independence Day notification cron job'
);

select cron.schedule(
  'india-independence-day-push',
  '30 3 15 8 *',
  $job$
    select net.http_post(
      url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-holiday-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-holiday-notification-secret',
          (select decrypted_secret from vault.decrypted_secrets
           where name = 'holiday_notification_secret')
      ),
      body := jsonb_build_object(
        'countryCode', 'IN',
        'title', 'Happy Independence Day! 🇮🇳',
        'body', 'स्वतंत्रता दिवस की शुभकामनाएँ',
        'eventId', 'india_independence_day'
      )
    );
  $job$
);

-- Manual test (run only after deployment). This sends to every device on country_IN.
-- select net.http_post(
--   url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-holiday-notification',
--   headers := jsonb_build_object(
--     'Content-Type', 'application/json',
--     'x-holiday-notification-secret',
--       (select decrypted_secret from vault.decrypted_secrets
--        where name = 'holiday_notification_secret')
--   ),
--   body := '{"countryCode":"IN"}'::jsonb
-- );
