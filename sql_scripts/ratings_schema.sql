-- Table to store individual ratings
CREATE TABLE IF NOT EXISTS user_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id TEXT NOT NULL, -- Kept as TEXT to support both UUID and BigInt IDs from help_requests
  rater_id UUID NOT NULL REFERENCES profiles(id),
  rated_id UUID NOT NULL REFERENCES profiles(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(request_id, rater_id, rated_id) -- Prevent multiple ratings for same transaction
);

-- Add rating_count to profiles if not exists (rating column already exists)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS rating_count INTEGER DEFAULT 0;

-- Function to update profile rating on new insert
CREATE OR REPLACE FUNCTION update_profile_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET 
    rating_count = (SELECT COUNT(*) FROM user_ratings WHERE rated_id = NEW.rated_id),
    rating = (SELECT COALESCE(AVG(rating), 0.0) FROM user_ratings WHERE rated_id = NEW.rated_id)
  WHERE id = NEW.rated_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
DROP TRIGGER IF EXISTS on_rating_added ON user_ratings;
CREATE TRIGGER on_rating_added
AFTER INSERT ON user_ratings
FOR EACH ROW EXECUTE PROCEDURE update_profile_rating();
