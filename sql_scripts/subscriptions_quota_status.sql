-- ============================================================================
-- get_ai_quota_status (Phase 3 of the subscription model, issue #80)
--
-- Apply by hand in the Supabase SQL editor AFTER subscriptions_schema.sql.
-- Safe to re-run.
--
-- Read-only. Lets the signed-in user see their own monthly AI quota so the app
-- can show "7 of 10 free AI actions left". It cannot change anything: spending
-- quota still goes through consume_ai_quota (service role only).
-- ============================================================================

create or replace function public.get_ai_quota_status()
returns table (
  used        integer,
  quota_limit integer,
  resets_at   timestamptz,
  is_pro      boolean,
  enforced    boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid     uuid := auth.uid();
  v_limit   integer;
  v_enabled boolean;
  v_pro     boolean;
  v_period  date := date_trunc('month', now() at time zone 'utc')::date;
  v_resets  timestamptz :=
    ((date_trunc('month', now() at time zone 'utc') + interval '1 month')
      at time zone 'utc');
  v_used    integer;
begin
  if v_uid is null then
    return;
  end if;

  select c.free_monthly_limit, c.enforcement_enabled
    into v_limit, v_enabled
    from public.ai_quota_config c
    limit 1;
  v_limit   := coalesce(v_limit, 10);
  v_enabled := coalesce(v_enabled, true);

  select exists (
    select 1
      from public.subscriptions s
     where s.user_id = v_uid
       and s.entitlement = 'pro'
       and s.status in ('trialing', 'active', 'past_due')
       and (s.current_period_end is null or s.current_period_end > now())
  ) into v_pro;

  select u.used_count into v_used
    from public.ai_usage u
   where u.user_id = v_uid and u.period_start = v_period;

  return query select coalesce(v_used, 0), v_limit, v_resets, v_pro, v_enabled;
end;
$$;

revoke all on function public.get_ai_quota_status() from public, anon;
grant execute on function public.get_ai_quota_status() to authenticated;
