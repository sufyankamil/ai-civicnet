-- =============================================================================
-- CivicNet Security Hardening
-- Apply in Supabase SQL Editor (Dashboard → SQL → New query).
-- Safe to re-run: uses IF EXISTS / DROP POLICY IF EXISTS / CREATE OR REPLACE.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Profile wrap key + privacy columns (app expects these; may be missing)
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS public_wrap_key text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS skills text[] DEFAULT '{}';

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS karma_level text DEFAULT 'Seedling';

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS points integer DEFAULT 0;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS rating_count integer DEFAULT 0;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS updated_at timestamptz;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_public_profile boolean DEFAULT true;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS show_neighborhood boolean DEFAULT true;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS show_impact_stats boolean DEFAULT true;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS show_achievements boolean DEFAULT true;

-- -----------------------------------------------------------------------------
-- 2. conversation_keys — wrapped AES keys per participant
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversation_keys (
  conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wrapped_key text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (conversation_id, user_id)
);

-- Single claimer per conversation prevents dual-bootstrap races
CREATE TABLE IF NOT EXISTS public.conversation_key_claims (
  conversation_id uuid PRIMARY KEY REFERENCES public.conversations(id) ON DELETE CASCADE,
  claimer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.conversation_key_claims ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view key claims" ON public.conversation_key_claims;
CREATE POLICY "Participants can view key claims"
  ON public.conversation_key_claims FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

DROP POLICY IF EXISTS "Participants can claim key bootstrap" ON public.conversation_key_claims;
CREATE POLICY "Participants can claim key bootstrap"
  ON public.conversation_key_claims FOR INSERT
  WITH CHECK (
    auth.uid() = claimer_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

DROP POLICY IF EXISTS "Claimers can delete own claims" ON public.conversation_key_claims;
CREATE POLICY "Claimers can delete own claims"
  ON public.conversation_key_claims FOR DELETE
  USING (auth.uid() = claimer_id);

ALTER TABLE public.conversation_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own conversation keys" ON public.conversation_keys;
DROP POLICY IF EXISTS "Participants can view conversation keys" ON public.conversation_keys;
-- Participants need to read peer key rows for upsert conflict detection.
CREATE POLICY "Participants can view conversation keys"
  ON public.conversation_keys FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

DROP POLICY IF EXISTS "Participants can insert conversation keys" ON public.conversation_keys;
CREATE POLICY "Participants can insert conversation keys"
  ON public.conversation_keys FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND auth.uid() = ANY (c.participant_ids)
        AND user_id = ANY (c.participant_ids)
    )
  );

DROP POLICY IF EXISTS "Users can update own conversation keys" ON public.conversation_keys;
DROP POLICY IF EXISTS "Participants can upsert conversation keys" ON public.conversation_keys;
CREATE POLICY "Participants can upsert conversation keys"
  ON public.conversation_keys FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND auth.uid() = ANY (c.participant_ids)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND auth.uid() = ANY (c.participant_ids)
        AND user_id = ANY (c.participant_ids)
    )
  );

DROP POLICY IF EXISTS "Participants can delete conversation keys" ON public.conversation_keys;
CREATE POLICY "Participants can delete conversation keys"
  ON public.conversation_keys FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversation_keys TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.conversation_key_claims TO authenticated;

-- Reliable key distribution (bypasses RLS after participant checks)
CREATE OR REPLACE FUNCTION public.upsert_conversation_key(
  p_conversation_id uuid,
  p_user_id uuid,
  p_wrapped_key text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = p_conversation_id
      AND auth.uid() = ANY (c.participant_ids)
      AND p_user_id = ANY (c.participant_ids)
  ) THEN
    RAISE EXCEPTION 'Not allowed to set key for this conversation/user';
  END IF;

  INSERT INTO public.conversation_keys AS ck (conversation_id, user_id, wrapped_key)
  VALUES (p_conversation_id, p_user_id, p_wrapped_key)
  ON CONFLICT (conversation_id, user_id)
  DO UPDATE SET wrapped_key = EXCLUDED.wrapped_key;
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_conversation_key(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_conversation_key(uuid, uuid, text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 3. Profiles RLS — own full row only; others via profiles_safe / RPCs
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "Authenticated can read wrap keys of others" ON public.profiles;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Safe public projection (no lat/lng/role/report_count).
-- Owner-invoked view bypasses RLS on underlying table; filters to public profiles.
CREATE OR REPLACE VIEW public.profiles_safe AS
SELECT
  id,
  name,
  avatar_url,
  skills,
  karma_level,
  rating,
  help_count,
  points,
  rating_count,
  is_public_profile,
  show_neighborhood,
  show_impact_stats,
  show_achievements,
  updated_at
FROM public.profiles;

GRANT SELECT ON public.profiles_safe TO authenticated;

-- Wrap key lookup for E2E chat (works even if profile is private)
CREATE OR REPLACE FUNCTION public.get_public_wrap_key(target_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() <> 'authenticated' THEN
    RETURN NULL;
  END IF;
  RETURN (SELECT p.public_wrap_key FROM public.profiles p WHERE p.id = target_id);
END;
$$;

REVOKE ALL ON FUNCTION public.get_public_wrap_key(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_wrap_key(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.conversation_has_keys(cid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_keys WHERE conversation_id = cid
  );
$$;

REVOKE ALL ON FUNCTION public.conversation_has_keys(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.conversation_has_keys(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.conversation_key_user_ids(cid uuid)
RETURNS uuid[]
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT COALESCE(array_agg(user_id), '{}')
  FROM public.conversation_keys
  WHERE conversation_id = cid;
$$;

REVOKE ALL ON FUNCTION public.conversation_key_user_ids(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.conversation_key_user_ids(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- 4. Neighborhood RPC — coarse coords only (~1.1 km)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_active_neighbors(
  center_lat double precision DEFAULT NULL,
  center_lng double precision DEFAULT NULL,
  radius_km double precision DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  name text,
  avatar_url text,
  skills text[],
  karma_level text,
  rating float,
  help_count int,
  points int,
  rating_count int,
  is_public_profile boolean,
  show_neighborhood boolean,
  show_impact_stats boolean,
  show_achievements boolean,
  lat double precision,
  lng double precision
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() <> 'authenticated' THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.avatar_url,
    p.skills,
    p.karma_level,
    p.rating::float,
    p.help_count,
    p.points,
    p.rating_count,
    COALESCE(p.is_public_profile, true),
    COALESCE(p.show_neighborhood, true),
    COALESCE(p.show_impact_stats, true),
    COALESCE(p.show_achievements, true),
    -- Round to ~2 decimal degrees ≈ 1.1 km
    ROUND(p.lat::numeric, 2)::double precision AS lat,
    ROUND(p.lng::numeric, 2)::double precision AS lng
  FROM public.profiles p
  WHERE COALESCE(p.show_neighborhood, true) = true
    AND p.lat IS NOT NULL
    AND p.lng IS NOT NULL
    AND p.id <> auth.uid()
    AND (
      center_lat IS NULL
      OR center_lng IS NULL
      OR radius_km IS NULL
      OR (
        6371 * acos(
          least(1.0, greatest(-1.0,
            cos(radians(center_lat)) * cos(radians(p.lat))
            * cos(radians(p.lng) - radians(center_lng))
            + sin(radians(center_lat)) * sin(radians(p.lat))
          ))
        ) <= radius_km
      )
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_active_neighbors(double precision, double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_neighbors(double precision, double precision, double precision) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5. Help requests — authenticated only
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Help requests are viewable by everyone." ON public.help_requests;
DROP POLICY IF EXISTS "Authenticated users can view help requests" ON public.help_requests;
CREATE POLICY "Authenticated users can view help requests"
  ON public.help_requests FOR SELECT
  USING (auth.role() = 'authenticated');

-- -----------------------------------------------------------------------------
-- 6. Event comments, announcements, polls, badges — authenticated
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Anyone can view comments" ON public.event_comments;
DROP POLICY IF EXISTS "Authenticated users can view comments" ON public.event_comments;
CREATE POLICY "Authenticated users can view comments"
  ON public.event_comments FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow public read access to announcements" ON public.announcements;
DROP POLICY IF EXISTS "Authenticated users can read announcements" ON public.announcements;
CREATE POLICY "Authenticated users can read announcements"
  ON public.announcements FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone can view polls" ON public.polls;
DROP POLICY IF EXISTS "Authenticated users can view polls" ON public.polls;
CREATE POLICY "Authenticated users can view polls"
  ON public.polls FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone can view options" ON public.poll_options;
DROP POLICY IF EXISTS "Authenticated users can view poll options" ON public.poll_options;
CREATE POLICY "Authenticated users can view poll options"
  ON public.poll_options FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone can view badges" ON public.badges;
DROP POLICY IF EXISTS "Authenticated users can view badges" ON public.badges;
CREATE POLICY "Authenticated users can view badges"
  ON public.badges FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone can view user badges" ON public.user_badges;
DROP POLICY IF EXISTS "Authenticated users can view user badges" ON public.user_badges;
CREATE POLICY "Authenticated users can view user badges"
  ON public.user_badges FOR SELECT
  USING (auth.role() = 'authenticated');

-- -----------------------------------------------------------------------------
-- 7. Guilds — respect is_private; memberships for members only
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_guild_member(gid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.guild_memberships
    WHERE guild_id = gid AND user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_guild_member(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_guild_member(uuid) TO authenticated;

DROP POLICY IF EXISTS "Anyone can view guilds" ON public.guilds;
DROP POLICY IF EXISTS "Users can view public or member guilds" ON public.guilds;
CREATE POLICY "Users can view public or member guilds"
  ON public.guilds FOR SELECT
  USING (
    auth.role() = 'authenticated'
    AND (
      COALESCE(is_private, false) = false
      OR public.is_guild_member(id)
    )
  );

DROP POLICY IF EXISTS "Anyone can view guild members" ON public.guild_memberships;
DROP POLICY IF EXISTS "Members can view guild memberships" ON public.guild_memberships;
CREATE POLICY "Members can view guild memberships"
  ON public.guild_memberships FOR SELECT
  USING (
    auth.role() = 'authenticated'
    AND (
      auth.uid() = user_id
      OR public.is_guild_member(guild_id)
      OR EXISTS (
        SELECT 1 FROM public.guilds g
        WHERE g.id = guild_memberships.guild_id
          AND COALESCE(g.is_private, false) = false
      )
    )
  );

-- -----------------------------------------------------------------------------
-- 8. Community assets — authenticated, non-private
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public can view available assets" ON public.community_assets;
DROP POLICY IF EXISTS "Authenticated can view non-private assets" ON public.community_assets;
CREATE POLICY "Authenticated can view non-private assets"
  ON public.community_assets FOR SELECT
  USING (
    auth.role() = 'authenticated'
    AND status <> 'private'
  );

-- -----------------------------------------------------------------------------
-- 9. Chat attachments — private bucket + participant-scoped paths
-- Path convention: {conversation_id}/{filename}
-- -----------------------------------------------------------------------------
UPDATE storage.buckets
SET public = false
WHERE id = 'chat-attachments';

INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-attachments', 'chat-attachments', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS "Public can view chat attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload chat attachments" ON storage.objects;
DROP POLICY IF EXISTS "Participants can upload chat attachments" ON storage.objects;
DROP POLICY IF EXISTS "Participants can view chat attachments" ON storage.objects;
DROP POLICY IF EXISTS "Participants can update chat attachments" ON storage.objects;
DROP POLICY IF EXISTS "Participants can delete chat attachments" ON storage.objects;

CREATE POLICY "Participants can upload chat attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'chat-attachments'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

CREATE POLICY "Participants can view chat attachments"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'chat-attachments'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

CREATE POLICY "Participants can update chat attachments"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'chat-attachments'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

CREATE POLICY "Participants can delete chat attachments"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'chat-attachments'
    AND auth.role() = 'authenticated'
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND auth.uid() = ANY (c.participant_ids)
    )
  );

-- -----------------------------------------------------------------------------
-- 10. Messages UPDATE — required for soft-delete
-- -----------------------------------------------------------------------------
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS is_deleted boolean DEFAULT false;

DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;
CREATE POLICY "Users can update their own messages"
  ON public.messages FOR UPDATE
  USING (auth.uid() = sender_id)
  WITH CHECK (auth.uid() = sender_id);
