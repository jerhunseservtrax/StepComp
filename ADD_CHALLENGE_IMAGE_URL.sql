-- ============================================
-- ADD IMAGE_URL TO CHALLENGES TABLE
-- ============================================
-- This script adds support for custom challenge images
-- Date: 2026-01-07

-- 1️⃣ Add image_url column to challenges table
ALTER TABLE public.challenges
ADD COLUMN IF NOT EXISTS image_url TEXT;

COMMENT ON COLUMN public.challenges.image_url IS 'Public URL of the challenge background image uploaded by creator';

-- 2️⃣ Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'challenges'
  AND column_name = 'image_url';

-- 3️⃣ Create storage bucket for challenge images (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('challenges', 'challenges', true)
ON CONFLICT (id) DO NOTHING;

-- 4️⃣ Set up RLS policies for challenge images storage
-- Allow authenticated users to upload challenge images
CREATE POLICY IF NOT EXISTS "Authenticated users can upload challenge images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'challenges' AND (storage.foldername(name))[1] = 'challenge-images');

-- Allow public read access to challenge images
CREATE POLICY IF NOT EXISTS "Public can view challenge images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'challenges');

-- Allow users to update their own challenge images
CREATE POLICY IF NOT EXISTS "Users can update their own challenge images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'challenges' AND owner = auth.uid());

-- Allow users to delete their own challenge images
CREATE POLICY IF NOT EXISTS "Users can delete their own challenge images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'challenges' AND owner = auth.uid());

-- ✅ COMPLETE
PRINT '✅ image_url column added to challenges table';
PRINT '✅ Storage bucket "challenges" created';
PRINT '✅ RLS policies set up for challenge images';
PRINT '';
PRINT '📸 Users can now upload custom images when creating challenges!';
PRINT '🎨 Images will be displayed as gradient backgrounds in discover cards';

