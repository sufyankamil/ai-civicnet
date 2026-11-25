-- ============================================================================
-- Subscriptions & AI quota (Phase 1 of the subscription model, issue #74)
--
-- Apply by hand in the Supabase SQL editor (there is no migration chain).
-- Safe to re-run: every statement is idempotent.
--
-- Access model:
--   * subscriptions: written ONLY by the service role (RevenueCat webhook in
--     Phase 2). Users can read their own row.
--   * ai_usage:      written ONLY through consume_ai_quota(), which only the
--     service role (the ai-proxy edge function) can execute.
--   * ai_quota_config: one row tuned from the dashboard; no client writes.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- subscriptions
-- ---------------------------------------------------------------------------
create table if not exists public.subscriptions (
  user_id            uuid primary key references auth.users(id) on delete cascade,
  entitlement        text not null default 'free'
                       check (entitlement in ('free', 'pro')),
  status             text not null default 'inactive'
                       check (status in
                         ('inactive', 'trialing', 'active', 'past_due', 'canceled', 'expired')),
  trial_ends_at      timestamptz,
  current_period_end timestamptz,
  source             text,
  updated_at         timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

drop policy if exists "Users read own subscription" on public.subscriptions;
create policy "Users read own subscription"
  on public.subscriptions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);
-- No insert/update/delete policies: only the service role may write.

-- ---------------------------------------------------------------------------
-- ai_usage: one row per user per calendar month (UTC)
-- ---------------------------------------------------------------------------
create table if not exists public.ai_usage (
  user_id      uuid not null references auth.users(id) on delete cascade,
  period_start date not null,
  used_count   integer not null default 0 check (used_count >= 0),
  primary key (user_id, period_start)
);

alter table public.ai_usage enable row level security;

drop policy if exists "Users read own AI usage" on public.ai_usage;
create policy "Users read own AI usage"
  on public.ai_usage
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- ai_quota_config: single row, tune without an app release
-- ---------------------------------------------------------------------------
create table if not exists public.ai_quota_config (
  id                  boolean primary key default true check (id),
  free_monthly_limit  integer not null default 10 check (free_monthly_limit >= 0),
  -- Soft-launch switch: set to false to stop enforcing the quota for everyone.
  enforcement_enabled boolean not null default true
);

insert into public.ai_quota_config (id) values (true)
on conflict (id) do nothing;

alter table public.ai_quota_config enable row level security;

drop policy if exists "Authenticated read AI quota config" on public.ai_quota_config;
create policy "Authenticated read AI quota config"
  on public.ai_quota_config
  for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- consume_ai_quota: atomically spend one metered AI action
-- ---------------------------------------------------------------------------
create or replace function public.consume_ai_quota(p_user_id uuid)
returns table (
  allowed     boolean,
  used        integer,
  quota_limit integer,
  resets_at   timestamptz,
  is_pro      boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit   integer;
  v_enabled boolean;
  v_pro     boolean;
  v_period  date := date_trunc('month', now() at time zone 'utc')::date;
  v_resets  timestamptz :=
    ((date_trunc('month', now() at time zone 'utc') + interval '1 month')
      at time zone 'utc');
  v_used    integer;
begin
  select c.free_monthly_limit, c.enforcement_enabled
    into v_limit, v_enabled
    from public.ai_quota_config c
    limit 1;
  v_limit   := coalesce(v_limit, 10);
  v_enabled := coalesce(v_enabled, true);

  select exists (
    select 1
      from public.subscriptions s
     where s.user_id = p_user_id
       and s.entitlement = 'pro'
       and s.status in ('trialing', 'active', 'past_due')
       and (s.current_period_end is null or s.current_period_end > now())
  ) into v_pro;

  -- Pro users and a disabled paywall are never metered.
  if v_pro or not v_enabled then
    return query select true, 0, v_limit, v_resets, v_pro;
    return;
  end if;

  if v_limit <= 0 then
    return query select false, 0, v_limit, v_resets, false;
    return;
  end if;

  -- Atomic increment that refuses to go past the limit (no read-then-write
  -- race between concurrent requests).
  insert into public.ai_usage as u (user_id, period_start, used_count)
  values (p_user_id, v_period, 1)
  on conflict (user_id, period_start)
  do update set used_count = u.used_count + 1
    where u.used_count < v_limit
  returning u.used_count into v_used;

  if v_used is null then
    select u.used_count into v_used
      from public.ai_usage u
     where u.user_id = p_user_id and u.period_start = v_period;
    return query select false, coalesce(v_used, v_limit), v_limit, v_resets, false;
  else
    return query select true, v_used, v_limit, v_resets, false;
  end if;
end;
$$;

-- Only the service role (the ai-proxy edge function, after it has verified the
-- caller's JWT) may spend quota. Clients must never call this directly.
revoke all on function public.consume_ai_quota(uuid) from public, anon, authenticated;
grant execute on function public.consume_ai_quota(uuid) to service_role;
