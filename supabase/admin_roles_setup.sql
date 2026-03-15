-- 1. Add role column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- 2. Update existing announcements table RLS 
-- First drop the old creation policy
DROP POLICY IF EXISTS "Allow authenticated users to create announcements" ON public.announcements;
DROP POLICY IF EXISTS "Allow only admins to create announcements" ON public.announcements;
DROP POLICY IF EXISTS "Allow admins to update announcements" ON public.announcements;
DROP POLICY IF EXISTS "Allow admins to delete announcements" ON public.announcements;

-- Create the new moderation policy
-- This policy checks if the author_id in the profiles table has the 'admin' role
CREATE POLICY "Allow only admins to create announcements"
ON public.announcements FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- Policy to allow admins to update ANY announcement
CREATE POLICY "Allow admins to update announcements"
ON public.announcements FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- Policy to allow admins to delete ANY announcement
CREATE POLICY "Allow admins to delete announcements"
ON public.announcements FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- 3. Update profiles table RLS to allow role management
DROP POLICY IF EXISTS "Allow admins to update user roles" ON public.profiles;
CREATE POLICY "Allow admins to update user roles"
ON public.profiles FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);
