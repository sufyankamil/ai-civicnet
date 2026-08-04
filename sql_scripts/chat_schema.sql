-- Create Conversations Table
create table if not exists conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  participant_ids uuid[] not null -- Array of user IDs in the chat
);

-- Create Messages Table
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references conversations(id) on delete cascade not null,
  sender_id uuid references auth.users(id) not null,
  content text, -- Text message or URL for media
  message_type text default 'text', -- 'text', 'image', 'audio'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  is_read boolean default false
);

-- RLS Policies for Conversations
alter table conversations enable row level security;

create policy "Users can view their own conversations"
  on conversations for select
  using (auth.uid() = any(participant_ids));

create policy "Users can insert conversations they are part of"
  on conversations for insert
  with check (auth.uid() = any(participant_ids));

create policy "Users can update their own conversations"
  on conversations for update
  using (auth.uid() = any(participant_ids));

-- RLS Policies for Messages
alter table messages enable row level security;

create policy "Users can view messages in their conversations"
  on messages for select
  using (
    exists (
      select 1 from conversations
      where id = messages.conversation_id
      and auth.uid() = any(participant_ids)
    )
  );

create policy "Users can insert messages in their conversations"
  on messages for insert
  with check (
    exists (
      select 1 from conversations
      where id = messages.conversation_id
      and auth.uid() = any(participant_ids)
    )
  );

-- Senders can soft-delete / edit their own messages
drop policy if exists "Users can update their own messages" on messages;
create policy "Users can update their own messages"
  on messages for update
  using (auth.uid() = sender_id)
  with check (auth.uid() = sender_id);

-- Storage for Chat Attachments (private — participants use signed URLs)
insert into storage.buckets (id, name, public) 
values ('chat-attachments', 'chat-attachments', false)
on conflict (id) do update set public = false;

drop policy if exists "Authenticated users can upload chat attachments" on storage.objects;
create policy "Authenticated users can upload chat attachments"
  on storage.objects for insert
  with check (
    bucket_id = 'chat-attachments' 
    and auth.role() = 'authenticated'
  );

drop policy if exists "Public can view chat attachments" on storage.objects;
drop policy if exists "Participants can view chat attachments" on storage.objects;
-- Prefer security_hardening.sql policies (path scoped by conversation_id).
create policy "Participants can view chat attachments"
  on storage.objects for select
  using (
    bucket_id = 'chat-attachments'
    and auth.role() = 'authenticated'
  );
