-- 1. Create Community Assets Table
CREATE TABLE IF NOT EXISTS public.community_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('Tools', 'Garden', 'Transport', 'Electronics', 'Household', 'Other')),
    image_url TEXT,
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'lent', 'private')),
    embedding vector(768), -- For AI Vector Matching (Gemini/OpenAI)
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE public.community_assets ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
-- Owners can do everything
DROP POLICY IF EXISTS "Users can manage their own assets" ON public.community_assets;
CREATE POLICY "Users can manage their own assets"
    ON public.community_assets
    FOR ALL
    USING (auth.uid() = owner_id);

-- Anyone can view public/available assets
DROP POLICY IF EXISTS "Public can view available assets" ON public.community_assets;
CREATE POLICY "Public can view available assets"
    ON public.community_assets
    FOR SELECT
    USING (status != 'private');

-- 4. Vector Matching RPC
DROP FUNCTION IF EXISTS public.match_assets_v1(vector, float8, int, uuid);

CREATE OR REPLACE FUNCTION public.match_assets_v1 (
  query_embedding vector(768),
  match_threshold float,
  match_count int,
  excluded_id uuid DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  owner_id uuid,
  owner_name text,
  title text,
  description text,
  category text,
  image_url text,
  status text,
  lat float8,
  lng float8,
  created_at timestamptz,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ca.id,
    ca.owner_id,
    p.name AS owner_name,
    ca.title,
    ca.description,
    ca.category,
    ca.image_url,
    ca.status,
    ca.lat,
    ca.lng,
    ca.created_at,
    1 - (ca.embedding <=> query_embedding) AS similarity
  FROM community_assets ca
  JOIN profiles p ON ca.owner_id = p.id
  WHERE (ca.status = 'available' OR ca.status = 'lent')
    AND (excluded_id IS NULL OR ca.owner_id != excluded_id)
    AND 1 - (ca.embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$;

-- 5. Helper Function to Update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_assets_updated_at ON public.community_assets;
CREATE TRIGGER update_assets_updated_at
BEFORE UPDATE ON public.community_assets
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 6. Storage Bucket for Asset Images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('asset-images', 'asset-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Authenticated users can upload asset images" ON storage.objects;
CREATE POLICY "Authenticated users can upload asset images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'asset-images' 
        AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Public can view asset images" ON storage.objects;
CREATE POLICY "Public can view asset images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'asset-images');
