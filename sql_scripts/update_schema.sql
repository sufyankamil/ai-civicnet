-- Add skills column to profiles table
alter table profiles 
add column if not exists skills text[] default '{}';

-- Check policy to ensure updates are allowed (already exists in setup_supabase.sql but good to verify)
-- create policy "Users can update own profile." on profiles for update using ( auth.uid() = id );
