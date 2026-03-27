-- 1. Enable pgvector extension
create extension if not exists vector;

-- 2. Add embedding columns (Gemini uses 768 dimensions)
alter table profiles add column if not exists embedding vector(768);
alter table help_requests add column if not exists embedding vector(768);

-- 3. Create a function to match requests by semantic similarity
-- This function will be called via RPC from Flutter
create or replace function match_requests_v3 (
  query_embedding vector(768),
  match_threshold float,
  match_count int,
  excluded_id uuid default null
)
returns table (
  id bigint,
  requester_id uuid,
  requester_name text,
  requester_avatar_url text,
  title text,
  description text,
  category text,
  urgency text,
  lat float,
  lng float,
  location_name text,
  status text,
  created_at timestamp with time zone,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    h.id,
    h.requester_id,
    p.name as requester_name,
    p.avatar_url as requester_avatar_url,
    h.title,
    h.description,
    h.category,
    h.urgency,
    h.lat,
    h.lng,
    h.location_name,
    h.status,
    h.created_at,
    1 - (h.embedding <=> query_embedding) as similarity
  from help_requests h
  join profiles p on h.requester_id = p.id
  where h.status = 'open'
    and (excluded_id is null or h.requester_id != excluded_id)
    and (1 - (h.embedding <=> query_embedding) > match_threshold)
  order by h.embedding <=> query_embedding
  limit match_count;
end;
$$;


-- 4. Create a function to match helpers for a specific request
-- This matches profile embeddings against a request embedding
create or replace function match_helpers_v3 (
  query_embedding vector(768),
  match_threshold float,
  match_count int,
  excluded_id uuid
)
returns table (
  id uuid,
  name text,
  avatar_url text,
  rating float,
  help_count int,
  skills text[],
  lat float,
  lng float,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    p.id,
    p.name,
    p.avatar_url,
    p.rating,
    p.help_count,
    p.skills,
    p.lat,
    p.lng,
    1 - (p.embedding <=> query_embedding) as similarity
  from profiles p
  where p.id != excluded_id
    and (1 - (p.embedding <=> query_embedding) > match_threshold)
  order by p.embedding <=> query_embedding
  limit match_count;
end;
$$;
