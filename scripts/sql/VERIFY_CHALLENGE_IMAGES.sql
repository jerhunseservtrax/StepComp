-- ============================================
-- VERIFY CHALLENGE IMAGE_URL COLUMN
-- ============================================
-- Run this to check if image_url column exists and see current data

-- 1️⃣ Check if image_url column exists
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'challenges'
  AND column_name = 'image_url';

-- 2️⃣ Check current challenges and their image URLs
SELECT 
    id,
    name,
    category,
    image_url,
    is_public,
    created_by,
    created_at
FROM public.challenges
ORDER BY created_at DESC
LIMIT 10;

-- 3️⃣ Count challenges with and without images
SELECT 
    COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') as with_image,
    COUNT(*) FILTER (WHERE image_url IS NULL OR image_url = '') as without_image,
    COUNT(*) as total
FROM public.challenges;

-- 4️⃣ Check storage bucket exists
SELECT id, name, public
FROM storage.buckets
WHERE id = 'challenges';

-- 5️⃣ Check if there are any files in the challenges bucket
SELECT 
    name,
    bucket_id,
    owner,
    created_at,
    updated_at
FROM storage.objects
WHERE bucket_id = 'challenges'
ORDER BY created_at DESC
LIMIT 5;

-- Success messages
DO $$
BEGIN
  RAISE NOTICE '✅ If image_url column exists and challenges bucket is set up, everything is ready!';
  RAISE NOTICE '⚠️ If image_url is NULL for existing challenges, they need to be recreated with images.';
  RAISE NOTICE '💡 New challenges with images will display correctly.';
END $$;

