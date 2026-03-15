-- Create the announcements table
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category TEXT DEFAULT 'community', -- warning, update, event, community
    image_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read announcements
CREATE POLICY "Allow public read access to announcements"
ON public.announcements FOR SELECT
USING (true);

-- Allow only authorized users (e.g., admins/community leaders) to insert/update
-- For now, allowing any authenticated user to create for testing, 
-- but in production, you'd restrict 'author_id' to specific roles.
CREATE POLICY "Allow authenticated users to create announcements"
ON public.announcements FOR INSERT
WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Allow users to update their own announcements"
ON public.announcements FOR UPDATE
USING (auth.uid() = author_id);

-- Optional: Indexing for performance
CREATE INDEX IF NOT EXISTS announcements_created_at_idx ON public.announcements (created_at DESC);
