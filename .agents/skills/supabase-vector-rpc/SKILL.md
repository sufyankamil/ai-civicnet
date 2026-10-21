---
name: supabase-vector-rpc
description: Guidelines for managing Supabase PostgreSQL schema, pgvector similarity matching, and RPC functions in CivicNet.
---

# Supabase & Vector Matching (pgvector) Guide

CivicNet's AI Opportunity Matching Engine pairs Gemini skill embeddings with help requests using PostgreSQL `pgvector`.

---

## 1. Key Tables & RPCs

- **`requests`**: Contains `title`, `description`, `category`, `urgency_level`, `location` (geometry/geography), and `embedding` (vector(768) from Google Gemini).
- **`profiles`**: Contains user skills, bio, verification status, and `skills_embedding`.
- **`match_requests_v3`**: RPC function performing cosine distance calculation (`<=>`) between request embeddings and user skills, filtered by distance threshold and active status.

---

## 2. Writing New Migrations

1. All new migrations must be stored under `sql_scripts/` or `supabase/migrations/` with timestamps or sequential numbering.
2. Always enable **Row Level Security (RLS)**:
   ```sql
   ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
   ```
3. Use `CREATE OR REPLACE FUNCTION` for RPC updates with `SECURITY DEFINER` only when elevated privileges are strictly necessary.
4. Ensure index creation on vector columns for production scalability:
   ```sql
   CREATE INDEX IF NOT EXISTS requests_embedding_hnsw_idx 
   ON requests USING hnsw (embedding vector_cosine_ops);
   ```

---

## 3. Invoking from Dart (`AIService` & `SupabaseService`)

- Generate embeddings via `google_generative_ai` (`embedding-001` or `text-embedding-004`).
- Call Supabase RPC:
  ```dart
  final response = await supabase.rpc('match_requests_v3', params: {
    'user_embedding': embedding,
    'match_threshold': 0.3,
    'match_count': 10,
    'user_lat': userLat,
    'user_long': userLong,
  });
  ```
