-- Create tables for Interest-Based Guilds (Sub-communities)

-- 1. Guilds Table
CREATE TABLE IF NOT EXISTS public.guilds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  category TEXT NOT NULL, -- e.g., 'Gardening', 'Tech', 'Sports'
  avatar_url TEXT,
  member_count INTEGER DEFAULT 1,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 2. Guild Memberships Table
CREATE TABLE IF NOT EXISTS public.guild_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guild_id UUID REFERENCES public.guilds(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member' NOT NULL, -- 'admin', 'moderator', 'member'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(guild_id, user_id)
);

-- Policies for Guilds
DROP POLICY IF EXISTS "Anyone can view guilds" ON public.guilds;
CREATE POLICY "Anyone can view guilds" ON public.guilds FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create guilds" ON public.guilds;
CREATE POLICY "Authenticated users can create guilds" ON public.guilds FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- Policies for Memberships
DROP POLICY IF EXISTS "Anyone can view guild members" ON public.guild_memberships;
CREATE POLICY "Anyone can view guild members" ON public.guild_memberships FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can join guilds" ON public.guild_memberships;
CREATE POLICY "Users can join guilds" ON public.guild_memberships FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can leave guilds" ON public.guild_memberships;
CREATE POLICY "Users can leave guilds" ON public.guild_memberships FOR DELETE USING (auth.uid() = user_id);

-- Trigger to update member_count in guilds
CREATE OR REPLACE FUNCTION public.handle_guild_membership_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.guilds SET member_count = member_count + 1 WHERE id = NEW.guild_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.guilds SET member_count = member_count - 1 WHERE id = OLD.guild_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_guild_membership_added ON public.guild_memberships;
CREATE TRIGGER on_guild_membership_added
  AFTER INSERT ON public.guild_memberships
  FOR EACH ROW EXECUTE FUNCTION public.handle_guild_membership_change();

DROP TRIGGER IF EXISTS on_guild_membership_removed ON public.guild_memberships;
CREATE TRIGGER on_guild_membership_removed
  AFTER DELETE ON public.guild_memberships
  FOR EACH ROW EXECUTE FUNCTION public.handle_guild_membership_change();
