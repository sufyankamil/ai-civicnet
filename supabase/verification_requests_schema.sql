-- 1. Create verification_requests table
CREATE TABLE IF NOT EXISTS public.verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- 3. Policies for regular users
DROP POLICY IF EXISTS "Users can create their own verification requests" ON public.verification_requests;
CREATE POLICY "Users can create their own verification requests"
ON public.verification_requests FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own verification requests" ON public.verification_requests;
CREATE POLICY "Users can view their own verification requests"
ON public.verification_requests FOR SELECT
USING (auth.uid() = user_id);

-- 4. Policies for admins
DROP POLICY IF EXISTS "Admins can view all verification requests" ON public.verification_requests;
CREATE POLICY "Admins can view all verification requests"
ON public.verification_requests FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

DROP POLICY IF EXISTS "Admins can update all verification requests" ON public.verification_requests;
CREATE POLICY "Admins can update all verification requests"
ON public.verification_requests FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- 5. Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_verification_requests_updated_at ON public.verification_requests;
CREATE TRIGGER update_verification_requests_updated_at
    BEFORE UPDATE ON public.verification_requests
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();
