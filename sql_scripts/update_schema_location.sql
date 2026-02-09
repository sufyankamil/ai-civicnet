-- Add location columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS lat float,
ADD COLUMN IF NOT EXISTS lng float;

-- Update RLS policies to allow users to update their own location (already covered by "Users can update own profile" policy, but good to verify)
-- The existing policy "Users can update own profile" covers all columns, so no change needed there.

-- Optional: Add a function to searching profiles by distance (if we wanted to do it on DB side)
-- For now, we will fetch and sort on client side for simplicity with small user base.
