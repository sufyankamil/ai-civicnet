-- Manual test for consume_ai_quota (run in the Supabase SQL editor on a DEV
-- project after applying sql_scripts/subscriptions_schema.sql).
-- Everything runs inside a transaction that is rolled back, so no data stays.
-- Each `assert` raises an error if the behavior is wrong; reaching the final
-- NOTICE means every check passed.

begin;

do $$
declare
  v_user uuid := gen_random_uuid();
  r      record;
  i      integer;
begin
  insert into auth.users (id, instance_id, aud, role, email)
  values (v_user, '00000000-0000-0000-0000-000000000000',
          'authenticated', 'authenticated', 'quota-test@example.invalid');

  update public.ai_quota_config set free_monthly_limit = 3, enforcement_enabled = true;

  -- Free user: first 3 calls allowed, 4th denied.
  for i in 1..3 loop
    select * into r from public.consume_ai_quota(v_user);
    assert r.allowed, format('call %s should be allowed', i);
    assert r.used = i, format('call %s should report used=%s, got %s', i, i, r.used);
    assert r.quota_limit = 3, 'limit should be 3';
  end loop;

  select * into r from public.consume_ai_quota(v_user);
  assert not r.allowed, '4th call must be denied';
  assert r.used = 3, 'denied call must not increment usage';

  -- Pro user bypasses the cap and is not metered.
  insert into public.subscriptions (user_id, entitlement, status, current_period_end)
  values (v_user, 'pro', 'active', now() + interval '30 days');
  select * into r from public.consume_ai_quota(v_user);
  assert r.allowed and r.is_pro, 'active pro must be allowed';

  -- Expired pro falls back to the free cap (already exhausted).
  update public.subscriptions set current_period_end = now() - interval '1 day'
   where user_id = v_user;
  select * into r from public.consume_ai_quota(v_user);
  assert not r.allowed, 'expired pro must be metered again';

  -- Soft-launch switch disables enforcement for everyone.
  update public.ai_quota_config set enforcement_enabled = false;
  select * into r from public.consume_ai_quota(v_user);
  assert r.allowed, 'disabled enforcement must allow';

  -- A zero limit denies free users.
  update public.ai_quota_config set enforcement_enabled = true, free_monthly_limit = 0;
  select * into r from public.consume_ai_quota(gen_random_uuid());
  assert not r.allowed, 'limit 0 must deny';

  raise notice 'consume_ai_quota: all checks passed';
end;
$$;

rollback;
