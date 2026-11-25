-- ============================================================================
-- RevenueCat sync (Phase 2 of the subscription model, issue #78)
--
-- Apply by hand in the Supabase SQL editor AFTER subscriptions_schema.sql.
-- Safe to re-run.
--
-- apply_subscription_event() is called only by the revenuecat-webhook edge
-- function (service role). It upserts a user's subscription row and ignores
-- events that are older than the last one applied, so duplicate or
-- out-of-order webhook deliveries cannot roll a user back.
-- ============================================================================

alter table public.subscriptions
  add column if not exists last_event_ms bigint not null default 0;

create or replace function public.apply_subscription_event(
  p_user_id            uuid,
  p_entitlement        text,
  p_status             text,
  p_trial_ends_at      timestamptz,
  p_current_period_end timestamptz,
  p_source             text,
  p_last_event_ms      bigint
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_applied boolean;
begin
  insert into public.subscriptions as s (
    user_id, entitlement, status, trial_ends_at, current_period_end,
    source, last_event_ms, updated_at
  )
  values (
    p_user_id, p_entitlement, p_status, p_trial_ends_at, p_current_period_end,
    p_source, p_last_event_ms, now()
  )
  on conflict (user_id) do update
    set entitlement        = excluded.entitlement,
        status             = excluded.status,
        trial_ends_at      = excluded.trial_ends_at,
        current_period_end = excluded.current_period_end,
        source             = excluded.source,
        last_event_ms      = excluded.last_event_ms,
        updated_at         = now()
    where s.last_event_ms < excluded.last_event_ms
  returning true into v_applied;

  -- No row returned means the event was stale and was skipped.
  return coalesce(v_applied, false);
end;
$$;

revoke all on function public.apply_subscription_event(
  uuid, text, text, timestamptz, timestamptz, text, bigint
) from public, anon, authenticated;
grant execute on function public.apply_subscription_event(
  uuid, text, text, timestamptz, timestamptz, text, bigint
) to service_role;
