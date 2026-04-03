-- Create tables for Community Polling

-- 1. Polls Table
CREATE TABLE IF NOT EXISTS public.polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  question TEXT NOT NULL,
  description TEXT,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  is_active BOOLEAN DEFAULT TRUE
);

-- 2. Poll Options Table
CREATE TABLE IF NOT EXISTS public.poll_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE NOT NULL,
  option_text TEXT NOT NULL,
  vote_count INTEGER DEFAULT 0
);

-- 3. Poll Votes Table (to prevent duplicate voting)
CREATE TABLE IF NOT EXISTS public.poll_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  option_id UUID REFERENCES public.poll_options(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(poll_id, user_id)
);

-- Policies for Polls
DROP POLICY IF EXISTS "Anyone can view polls" ON public.polls;
CREATE POLICY "Anyone can view polls" ON public.polls FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can create polls" ON public.polls;
CREATE POLICY "Admins can create polls" ON public.polls FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'super_admin'))
);

DROP POLICY IF EXISTS "Creators can delete their own polls" ON public.polls;
CREATE POLICY "Creators can delete their own polls" ON public.polls FOR DELETE USING (auth.uid() = creator_id);

-- Policies for Options
DROP POLICY IF EXISTS "Anyone can view options" ON public.poll_options;
CREATE POLICY "Anyone can view options" ON public.poll_options FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can insert options" ON public.poll_options;
CREATE POLICY "Admins can insert options" ON public.poll_options FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'admin' OR role = 'super_admin'))
);

-- Policies for Votes
DROP POLICY IF EXISTS "Users can view their own votes" ON public.poll_votes;
CREATE POLICY "Users can view their own votes" ON public.poll_votes FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can vote" ON public.poll_votes;
CREATE POLICY "Users can vote" ON public.poll_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger to increment vote_count in poll_options
CREATE OR REPLACE FUNCTION public.handle_new_vote()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.poll_options
  SET vote_count = vote_count + 1
  WHERE id = NEW.option_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_vote_inserted ON public.poll_votes;
CREATE TRIGGER on_vote_inserted
  AFTER INSERT ON public.poll_votes
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_vote();
