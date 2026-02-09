-- Create table for storing help request applications (interest)
create table public.request_applications (
  id uuid not null default gen_random_uuid (),
  request_id bigint not null references public.help_requests (id) on delete cascade,
  applicant_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending', -- pending, accepted, rejected
  created_at timestamp with time zone not null default now(),
  primary key (id),
  unique (request_id, applicant_id) -- Prevent duplicate applications
);

-- Enable RLS
alter table public.request_applications enable row level security;

-- Policies

-- Applicants can view their own applications
create policy "Applicants can view their own applications"
on public.request_applications
for select
using (auth.uid() = applicant_id);

-- Requesters can view applications for their requests
create policy "Requesters can view applications for their requests"
on public.request_applications
for select
using (
  exists (
    select 1 from public.help_requests
    where id = request_applications.request_id
    and requester_id = auth.uid()
  )
);

-- Users can insert their own applications
create policy "Users can apply to requests"
on public.request_applications
for insert
with check (auth.uid() = applicant_id);

-- Requesters can update status of applications for their requests
create policy "Requesters can update application status"
on public.request_applications
for update
using (
  exists (
    select 1 from public.help_requests
    where id = request_applications.request_id
    and requester_id = auth.uid()
  )
);
