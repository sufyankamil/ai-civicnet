-- Add points column to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;

-- Add helper_id to help_requests to track who completed the task
ALTER TABLE help_requests 
ADD COLUMN IF NOT EXISTS helper_id UUID REFERENCES profiles(id);

-- Function to complete request and award points transactionally
-- Drop existing functions to avoid "multiple choices" error (overloading ambiguity)
DROP FUNCTION IF EXISTS complete_help_request(UUID, UUID);
DROP FUNCTION IF EXISTS complete_help_request(TEXT, UUID);

CREATE OR REPLACE FUNCTION complete_help_request(
  p_request_id TEXT, -- Changed from UUID to TEXT to handle both UUIDs and numeric IDs
  p_helper_id UUID
) RETURNS VOID AS $$
DECLARE
  v_requester_id UUID;
  v_status TEXT;
  v_request_pk_is_uuid BOOLEAN;
BEGIN
  -- Determine if we should treat input as UUID or Integer based on content
  -- (Naive check: if it parses as int, use it as such, but id column type matches automatically usually if we cast to text? 
  -- actually, better to just rely on implicit cast if the column is TEXT/UUID, but if column is BIGINT we need a cast)
  
  -- SIMPLER APPROACH: Since we don't know if 'id' is UUID or BIGINT, we can try to cast carefully
  -- OR we can just assume if it's "6" it's bigint.
  
  -- But wait, we can't write dynamic SQL easily here.
  -- Let's try to select based on the variable cast.
  -- If the DB has BIGINT id, `id = p_request_id::bigint` works.
  -- If the DB has UUID id, `id = p_request_id::uuid` works.
  
  -- Given the error 'invalid input syntax for type uuid: "6"', the table DEFINITELY has integer IDs.
  -- Otherwise insert of "6" would have failed long ago.
  -- So we can treat it as BIGINT.
  
  -- Get request details
  SELECT requester_id, status INTO v_requester_id, v_status
  FROM help_requests
  WHERE id::text = p_request_id; -- Cast table column to text to compare with input text safely

  -- Validation
  IF v_status = 'completed' THEN
    RAISE EXCEPTION 'Request is already completed';
  END IF;

  -- Update request status and helper
  UPDATE help_requests
  SET status = 'completed',
      helper_id = p_helper_id
  WHERE id::text = p_request_id;

  -- Award points to Helper (+15)
  UPDATE profiles
  SET points = points + 15
  WHERE id = p_helper_id;

  -- Award points to Requester (+5)
  UPDATE profiles
  SET points = points + 5
  WHERE id = v_requester_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
