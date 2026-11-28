-- Manual test for sql_scripts/sos_schema.sql. Run in the Supabase SQL editor on
-- a DEV project after applying sos_schema.sql. Everything runs in a transaction
-- that is rolled back, so no data stays. Each `assert` raises if wrong; reaching
-- the final NOTICE means every check passed.

begin;

do $$
declare
  v_a uuid := gen_random_uuid();   -- person in trouble
  v_near uuid := gen_random_uuid(); -- helper close by
  v_far uuid := gen_random_uuid();  -- helper too far
  v_blk uuid := gen_random_uuid();  -- helper who blocked A
  v_old uuid := gen_random_uuid();  -- helper with a stale token
  v_id bigint;
  v_id2 bigint;
  r record;
  n integer;
begin
  insert into auth.users (id, instance_id, aud, role, email)
  select u, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         u::text || '@example.invalid'
  from unnest(array[v_a, v_near, v_far, v_blk, v_old]) as u;
  insert into public.profiles (id, name)
  select u, 'test' from unnest(array[v_a, v_near, v_far, v_blk, v_old]) as u
  on conflict (id) do nothing;

  -- Act as user A.
  perform set_config('request.jwt.claims', json_build_object('sub', v_a)::text, true);

  -- create_sos stores a rounded public location and the exact one privately.
  v_id := public.create_sos(19.076012, 72.877698, null);
  select * into r from public.help_requests where id = v_id;
  assert r.is_sos and r.category = 'Emergency' and r.urgency = 'critical', 'sos row shape';
  assert r.lat = 19.076 and r.lng = 72.878, format('public location must be rounded, got %s,%s', r.lat, r.lng);
  assert r.sos_expires_at > now() + interval '59 minutes', 'expires in about 60 minutes';
  select * into r from public.sos_locations where request_id = v_id;
  assert r.lat = 19.076012 and r.lng = 72.877698, 'exact location stored privately';

  -- Rate limit: a second SOS right away is refused.
  begin
    perform public.create_sos(19.0, 72.8, null);
    assert false, 'second SOS within 10 minutes must be refused';
  exception when others then
    assert sqlerrm = 'sos_rate_limited' or sqlerrm = 'sos_already_active', format('unexpected error: %s', sqlerrm);
  end;

  -- Daily limit: pretend 3 old ones already happened today.
  update public.help_requests set created_at = now() - interval '30 minutes', status = 'closed' where id = v_id;
  insert into public.help_requests (requester_id, title, description, category, urgency, lat, lng, status, is_sos, sos_expires_at, created_at)
  select v_a, 'old', 'old', 'Emergency', 'critical', 19.0, 72.8, 'closed', true, now(), now() - interval '2 hours'
  from generate_series(1, 2);
  begin
    perform public.create_sos(19.0, 72.8, null);
    assert false, 'fourth SOS in 24 hours must be refused';
  exception when others then
    assert sqlerrm = 'sos_daily_limit', format('unexpected error: %s', sqlerrm);
  end;

  -- Recipients. Reset to one SOS in the last day so we can create a fresh one.
  delete from public.help_requests where requester_id = v_a;
  v_id2 := public.create_sos(19.076012, 72.877698, 'test');

  perform set_config('request.jwt.claims', null, true);

  insert into public.device_tokens (user_id, token, platform, lat, lng, updated_at) values
    (v_a,    'tok-self', 'ios', 19.076, 72.878, now()),
    (v_near, 'tok-near', 'ios', 19.080, 72.880, now()),     -- about 500 m
    (v_far,  'tok-far',  'ios', 19.200, 72.900, now()),     -- about 14 km
    (v_blk,  'tok-blk',  'ios', 19.077, 72.878, now()),
    (v_old,  'tok-old',  'ios', 19.077, 72.878, now() - interval '40 days');
  insert into public.blocked_users (blocker_id, blocked_id) values (v_blk, v_a);

  select count(*) into n from public.sos_recipient_tokens(v_id2, 2000);
  assert n = 1, format('exactly one helper should be alerted, got %s', n);
  assert exists (select 1 from public.sos_recipient_tokens(v_id2, 2000) where token = 'tok-near'), 'near helper alerted';

  -- Exact location is hidden from other users and visible to the requester.
  perform set_config('request.jwt.claims', json_build_object('sub', v_near)::text, true);
  set local role authenticated;
  select count(*) into n from public.sos_locations where request_id = v_id2;
  assert n = 0, 'other users must not read the exact location';
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_a)::text, true);
  set local role authenticated;
  select count(*) into n from public.sos_locations where request_id = v_id2;
  assert n = 1, 'requester reads the exact location';
  reset role;

  raise notice 'sos_test: all checks passed';
end $$;

rollback;
