-- Reputation System (Civic Karma) Improvements

-- 1. Add karma_level to profiles if not exists
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='karma_level') THEN
    ALTER TABLE public.profiles ADD COLUMN karma_level TEXT DEFAULT 'Seedling';
  END IF;
END $$;

-- 2. Create Badges Table
CREATE TABLE IF NOT EXISTS public.badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon_url TEXT,
  requirement_type TEXT NOT NULL, -- 'points', 'guilds', 'polls', 'help_given'
  requirement_value INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 3. Create User Badges Table
CREATE TABLE IF NOT EXISTS public.user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  badge_id UUID REFERENCES public.badges(id) ON DELETE CASCADE NOT NULL,
  awarded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, badge_id)
);

-- Policies
DROP POLICY IF EXISTS "Anyone can view badges" ON public.badges;
CREATE POLICY "Anyone can view badges" ON public.badges FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view user badges" ON public.user_badges;
CREATE POLICY "Anyone can view user badges" ON public.user_badges FOR SELECT USING (true);

-- 4. Trigger to update karma_level based on points
CREATE OR REPLACE FUNCTION public.update_karma_level()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.points >= 1000 THEN
    NEW.karma_level := 'Community Pillar';
  ELSIF NEW.points >= 500 THEN
    NEW.karma_level := 'Local Hero';
  ELSIF NEW.points >= 200 THEN
    NEW.karma_level := 'Active Citizen';
  ELSIF NEW.points >= 50 THEN
    NEW.karma_level := 'Growing Sprout';
  ELSE
    NEW.karma_level := 'Seedling';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_points_updated ON public.profiles;
CREATE TRIGGER on_points_updated
  BEFORE UPDATE OF points ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_karma_level();

-- 5. Seed initial badges
INSERT INTO public.badges (name, description, requirement_type, requirement_value)
VALUES 
  ('First Responder', 'Completed your first help request', 'help_given', 1),
  ('Community Voice', 'Voted in 5 community polls', 'polls', 5),
  ('Social Butterfly', 'Joined 3 different guilds', 'guilds', 3),
  ('Century Club', 'Earned 100 points', 'points', 100)
ON CONFLICT (name) DO NOTHING;

-- 6. Centralized Karma Engine Functions
CREATE OR REPLACE FUNCTION public.check_and_award_badges(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_badge RECORD;
  v_count INTEGER;
  v_points INTEGER;
BEGIN
  -- Get user's current points
  SELECT points INTO v_points FROM public.profiles WHERE id = p_user_id;

  FOR v_badge IN SELECT * FROM public.badges LOOP
    v_count := 0;
    
    -- Check requirements
    CASE v_badge.requirement_type
      WHEN 'points' THEN
        v_count := v_points;
      WHEN 'polls' THEN
        SELECT COUNT(*) INTO v_count FROM public.poll_votes WHERE user_id = p_user_id;
      WHEN 'guilds' THEN
        SELECT COUNT(*) INTO v_count FROM public.guild_memberships WHERE user_id = p_user_id;
      WHEN 'help_given' THEN
        SELECT COUNT(*) INTO v_count FROM public.help_requests WHERE helper_id = p_user_id AND status = 'completed';
    END CASE;

    -- Award badge if requirement met and not already awarded
    IF v_count >= v_badge.requirement_value THEN
      INSERT INTO public.user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge.id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.award_points(p_user_id UUID, p_amount INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET points = points + p_amount
  WHERE id = p_user_id;
  
  -- Run badge check after points increase
  PERFORM public.check_and_award_badges(p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Add Triggers for Automated Point Awarding

-- A. Points for voting in polls (+2)
CREATE OR REPLACE FUNCTION public.handle_poll_vote_karma()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.award_points(NEW.user_id, 2);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_poll_vote_karma ON public.poll_votes;
CREATE TRIGGER on_poll_vote_karma
  AFTER INSERT ON public.poll_votes
  FOR EACH ROW EXECUTE FUNCTION public.handle_poll_vote_karma();

-- B. Points for joining guilds (+5)
CREATE OR REPLACE FUNCTION public.handle_guild_join_karma()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.award_points(NEW.user_id, 5);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_guild_join_karma ON public.guild_memberships;
CREATE TRIGGER on_guild_join_karma
  AFTER INSERT ON public.guild_memberships
  FOR EACH ROW EXECUTE FUNCTION public.handle_guild_join_karma();

-- C. Points for creating polls (+10)
CREATE OR REPLACE FUNCTION public.handle_poll_create_karma()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.award_points(NEW.creator_id, 10);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_poll_create_karma ON public.polls;
CREATE TRIGGER on_poll_create_karma
  AFTER INSERT ON public.polls
  FOR EACH ROW EXECUTE FUNCTION public.handle_poll_create_karma();
