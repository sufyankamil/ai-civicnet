-- Create Event Comments Table
create table if not exists public.event_comments (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.local_events(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  parent_id uuid references public.event_comments(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.event_comments enable row level security;

-- Policies
-- Anyone can view comments
create policy "Anyone can view comments"
  on public.event_comments for select
  using (true);

-- Authenticated users can insert comments
create policy "Authenticated users can insert event comments"
  on public.event_comments for insert
  with check (auth.role() = 'authenticated');

-- Optional: Allow users to delete their own comments
create policy "Users can delete their own comments"
  on public.event_comments for delete
  using (auth.uid() = user_id);
