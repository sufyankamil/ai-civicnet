-- Run this once in the Supabase SQL editor before deploying the app update.
-- Country is intentionally selected by the user, never inferred from GPS or IP.
alter table public.profiles
  add column if not exists country_code text;

alter table public.profiles
  drop constraint if exists profiles_country_code_format;

alter table public.profiles
  add constraint profiles_country_code_format
  check (country_code is null or country_code ~ '^[A-Z]{2}$');

comment on column public.profiles.country_code is
  'User-selected ISO 3166-1 alpha-2 country code for regional notification topics.';
