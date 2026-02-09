-- Add report_count to profiles if it doesn't exist
alter table profiles add column if not exists report_count int default 0;

-- Create blocked_users table
create table if not exists blocked_users (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid references profiles(id) not null,
  blocked_id uuid references profiles(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(blocker_id, blocked_id)
);

-- Create user_reports table
create table if not exists user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles(id) not null,
  reported_id uuid references profiles(id) not null,
  reason text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for blocked_users
alter table blocked_users enable row level security;

create policy "Users can view who they blocked"
  on blocked_users for select
  using (auth.uid() = blocker_id);

create policy "Users can block others"
  on blocked_users for insert
  with check (auth.uid() = blocker_id);

create policy "Users can unblock others"
  on blocked_users for delete
  using (auth.uid() = blocker_id);

-- RLS for user_reports
alter table user_reports enable row level security;

create policy "Users can insert reports"
  on user_reports for insert
  with check (auth.uid() = reporter_id);

-- Function to handle report counting
create or replace function public.handle_new_report()
returns trigger as $$
begin
  update public.profiles
  set report_count = report_count + 1
  where id = new.reported_id;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger for report counting
drop trigger if exists on_report_created on user_reports;
create trigger on_report_created
  after insert on user_reports
  for each row execute procedure public.handle_new_report();
