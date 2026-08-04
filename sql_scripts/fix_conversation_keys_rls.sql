-- Fix: conversation_keys RLS blocking sends
-- Run this in Supabase SQL Editor, then hot-restart the app.

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversation_keys TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.conversation_key_claims TO authenticated;

DROP POLICY IF EXISTS "Users can view own conversation keys" ON public.conversation_keys;
DROP POLICY IF EXISTS "Participants can view conversation keys" ON public.conversation_keys;
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
