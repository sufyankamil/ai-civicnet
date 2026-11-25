-- Daily GCC national-day greeting pushes (issue #82).
--
-- Run once in the Supabase SQL editor AFTER deploying the updated
-- send-holiday-notification function. Replace <PROJECT_REF> before running.
--
-- It reuses the vault secret created by holiday_notification_schedule.sql
-- ('holiday_notification_secret') and the HOLIDAY_NOTIFICATION_SECRET function
-- secret. If you never ran that script, create the secret first:
--   select vault.create_secret('<A_LONG_RANDOM_SECRET>', 'holiday_notification_secret',
--     'Secret used by the holiday notification cron jobs');
--   (and `supabase secrets set HOLIDAY_NOTIFICATION_SECRET=<same value>`)
--
-- The jobs run every day and the function decides whether today is a holiday,
-- using each country's own time zone and the dates in holidays.ts. Two jobs are
-- needed only to send at 09:00 local time:
--   * UAE and Oman are UTC+4  -> 05:00 UTC
--   * Saudi Arabia, Kuwait, Qatar and Bahrain are UTC+3 -> 06:00 UTC
-- On a normal day the function sends nothing.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'gcc-holiday-greetings-utc4',
  '0 5 * * *',
  $job$
    select net.http_post(
      url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-holiday-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-holiday-notification-secret',
          (select decrypted_secret from vault.decrypted_secrets
           where name = 'holiday_notification_secret')
      ),
      body := '{"daily": true, "countryCodes": ["AE", "OM"]}'::jsonb
    );
  $job$
);

select cron.schedule(
  'gcc-holiday-greetings-utc3',
  '0 6 * * *',
  $job$
    select net.http_post(
      url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-holiday-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-holiday-notification-secret',
          (select decrypted_secret from vault.decrypted_secrets
           where name = 'holiday_notification_secret')
      ),
      body := '{"daily": true, "countryCodes": ["SA", "KW", "QA", "BH"]}'::jsonb
    );
  $job$
);

-- To stop them later:
--   select cron.unschedule('gcc-holiday-greetings-utc4');
--   select cron.unschedule('gcc-holiday-greetings-utc3');
