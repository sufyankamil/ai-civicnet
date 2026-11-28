-- Emergency SOS (issue #108). Design: docs/design/sos-and-offers.md
-- Apply by hand in the Supabase SQL editor, then run sql_scripts/tests/sos_test.sql
-- on a DEV project. Safe to run more than once.
--
-- After applying:
--  1. Deploy the edge function:        supabase functions deploy notify-sos
--  2. Set its secret:                  supabase secrets set NOTIFY_SOS_SECRET=<long random string>
--  3. Create a Database Webhook (Database -> Webhooks) named `notify_on_sos`:
--       table help_requests, event Insert, type HTTP Request / Edge Function `notify-sos`,
--       with the HTTP header  x-webhook-secret: <the same string>
--  4. Re-deploy notify-new-request (it now skips SOS rows).

-- -----------------------------------------------------------------------------
-- 1. help_requests: SOS columns
-- -----------------------------------------------------------------------------
ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS is_sos boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sos_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS sos_notified_at timestamptz,
  ADD COLUMN IF NOT EXISTS sos_alert_count integer;

CREATE INDEX IF NOT EXISTS help_requests_sos_idx
  ON public.help_requests (requester_id, created_at DESC) WHERE is_sos;

-- -----------------------------------------------------------------------------
-- 2. Exact SOS location: readable only by the requester and an accepted helper.
--    (help_requests is readable by every signed-in user, so its lat/lng is
--    rounded to about 110 m for SOS rows.)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sos_locations (
  request_id   bigint PRIMARY KEY REFERENCES public.help_requests (id) ON DELETE CASCADE,
  requester_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  lat          double precision NOT NULL,
  lng          double precision NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.sos_locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Requester or accepted helper reads SOS location" ON public.sos_locations;
CREATE POLICY "Requester or accepted helper reads SOS location"
  ON public.sos_locations FOR SELECT
  USING (
    auth.uid() = requester_id
    OR EXISTS (
      SELECT 1 FROM public.request_applications a
      WHERE a.request_id = sos_locations.request_id
        AND a.applicant_id = auth.uid()
        AND a.status = 'accepted'
    )
  );
-- No insert/update/delete policies: rows are written only by create_sos().

-- -----------------------------------------------------------------------------
-- 3. Device tokens for geo-targeted push. Location is rounded to about 550 m.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  token      text NOT NULL UNIQUE,
  platform   text NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  lat        double precision,
  lng        double precision,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS device_tokens_user_idx ON public.device_tokens (user_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read their own device tokens" ON public.device_tokens;
CREATE POLICY "Users read their own device tokens"
  ON public.device_tokens FOR SELECT
  USING (auth.uid() = user_id);
-- Writes go through register_device_token / unregister_device_token only.

CREATE OR REPLACE FUNCTION public.register_device_token(
  p_token text, p_platform text, p_lat double precision DEFAULT NULL, p_lng double precision DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF p_token IS NULL OR length(p_token) < 20 OR length(p_token) > 4096 THEN
    RAISE EXCEPTION 'invalid token' USING ERRCODE = '22023';
  END IF;
  IF p_platform NOT IN ('ios', 'android', 'web') THEN
    RAISE EXCEPTION 'invalid platform' USING ERRCODE = '22023';
  END IF;
  IF (p_lat IS NOT NULL AND p_lat NOT BETWEEN -90 AND 90)
     OR (p_lng IS NOT NULL AND p_lng NOT BETWEEN -180 AND 180) THEN
    RAISE EXCEPTION 'invalid location' USING ERRCODE = '22023';
  END IF;

  -- Round to 0.005 degrees (about 550 m) so exact positions are never stored.
  INSERT INTO public.device_tokens (user_id, token, platform, lat, lng, updated_at)
  VALUES (
    v_uid, p_token, p_platform,
    CASE WHEN p_lat IS NULL THEN NULL ELSE round((p_lat * 200)::numeric) / 200 END,
    CASE WHEN p_lng IS NULL THEN NULL ELSE round((p_lng * 200)::numeric) / 200 END,
    now()
  )
  ON CONFLICT (token) DO UPDATE
    SET user_id = EXCLUDED.user_id,
        platform = EXCLUDED.platform,
        lat = COALESCE(EXCLUDED.lat, public.device_tokens.lat),
        lng = COALESCE(EXCLUDED.lng, public.device_tokens.lng),
        updated_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.unregister_device_token(p_token text)
RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  DELETE FROM public.device_tokens WHERE token = p_token AND user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.register_device_token(text, text, double precision, double precision) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.unregister_device_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_device_token(text, text, double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unregister_device_token(text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 4. create_sos: the only way to create an SOS. Enforces the limits.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_sos(
  p_lat double precision, p_lng double precision, p_note text DEFAULT NULL
) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_id bigint;
  v_recent integer;
  v_day integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF p_lat IS NULL OR p_lng IS NULL OR p_lat NOT BETWEEN -90 AND 90 OR p_lng NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'invalid location' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.help_requests
    WHERE requester_id = v_uid AND is_sos AND status = 'open' AND sos_expires_at > now()
  ) THEN
    RAISE EXCEPTION 'sos_already_active' USING ERRCODE = 'P0001';
  END IF;

  SELECT count(*) INTO v_recent FROM public.help_requests
    WHERE requester_id = v_uid AND is_sos AND created_at > now() - interval '10 minutes';
  IF v_recent >= 1 THEN
    RAISE EXCEPTION 'sos_rate_limited' USING ERRCODE = 'P0001';
  END IF;

  SELECT count(*) INTO v_day FROM public.help_requests
    WHERE requester_id = v_uid AND is_sos AND created_at > now() - interval '24 hours';
  IF v_day >= 3 THEN
    RAISE EXCEPTION 'sos_daily_limit' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.help_requests (
    requester_id, title, description, category, urgency, lat, lng, status, is_sos, sos_expires_at
  ) VALUES (
    v_uid,
    'SOS: I need help now',
    COALESCE(NULLIF(left(trim(p_note), 300), ''), 'I need urgent help nearby.'),
    'Emergency', 'critical',
    round(p_lat::numeric, 3), round(p_lng::numeric, 3),
    'open', true, now() + interval '60 minutes'
  ) RETURNING id INTO v_id;

  INSERT INTO public.sos_locations (request_id, requester_id, lat, lng)
  VALUES (v_id, v_uid, p_lat, p_lng);

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_sos(double precision, double precision, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_sos(double precision, double precision, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5. end_sos: requester marks themselves safe (or cancels).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.end_sos(p_request_id bigint)
RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.help_requests
     SET status = 'closed', sos_expires_at = LEAST(COALESCE(sos_expires_at, now()), now())
   WHERE id = p_request_id AND requester_id = auth.uid() AND is_sos AND status <> 'closed';
$$;

REVOKE ALL ON FUNCTION public.end_sos(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.end_sos(bigint) TO authenticated;

-- -----------------------------------------------------------------------------
-- 6. Recipients for the notify-sos edge function (service role only).
--    Within p_radius_m of the exact SOS location (plus 550 m for the rounding of
--    token locations), seen in the last 30 days, never the requester, never
--    anyone who blocked them or whom they blocked.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sos_recipient_tokens(p_request_id bigint, p_radius_m integer DEFAULT 2000)
RETURNS TABLE (token text, platform text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT DISTINCT dt.token, dt.platform
  FROM public.help_requests r
  JOIN public.sos_locations l ON l.request_id = r.id
  JOIN public.device_tokens dt ON dt.user_id <> r.requester_id
  WHERE r.id = p_request_id
    AND r.is_sos
    AND dt.updated_at > now() - interval '30 days'
    AND dt.lat IS NOT NULL AND dt.lng IS NOT NULL
    AND 2 * 6371000 * asin(sqrt(
          power(sin(radians(dt.lat - l.lat) / 2), 2)
          + cos(radians(l.lat)) * cos(radians(dt.lat)) * power(sin(radians(dt.lng - l.lng) / 2), 2)
        )) <= (p_radius_m + 550)
    AND NOT EXISTS (
      SELECT 1 FROM public.blocked_users b
      WHERE (b.blocker_id = dt.user_id AND b.blocked_id = r.requester_id)
         OR (b.blocker_id = r.requester_id AND b.blocked_id = dt.user_id)
    );
$$;

REVOKE ALL ON FUNCTION public.sos_recipient_tokens(bigint, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sos_recipient_tokens(bigint, integer) TO service_role;
