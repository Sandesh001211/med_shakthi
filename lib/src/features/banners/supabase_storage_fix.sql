-- ============================================
-- Supabase Storage Bucket Policies for Banners
-- ============================================
-- Run this SQL in Supabase SQL Editor to fix the storage upload error
-- ============================================

-- 1️⃣ CREATE STORAGE BUCKET (if not already created)
-- You may have already created this via UI, so this might error - that's OK!
INSERT INTO storage.buckets (id, name, public)
VALUES ('banner-images', 'banner-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2️⃣ ENABLE RLS ON STORAGE OBJECTS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3️⃣ DROP EXISTING POLICIES (if any)
DROP POLICY IF EXISTS "Anyone can view banner images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload banner images" ON storage.objects;
DROP POLICY IF EXISTS "Suppliers can upload their own banner images" ON storage.objects;
DROP POLICY IF EXISTS "Suppliers can delete their own banner images" ON storage.objects;

-- 4️⃣ CREATE STORAGE POLICIES

-- Policy: Anyone can view/download banner images (public bucket)
CREATE POLICY "Anyone can view banner images"
ON storage.objects FOR SELECT
USING (bucket_id = 'banner-images');

-- Policy: Authenticated users can upload to banner-images bucket
CREATE POLICY "Authenticated users can upload banner images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'banner-images' 
  AND auth.role() = 'authenticated'
);

-- Policy: Users can update their own banner images
CREATE POLICY "Users can update their own banner images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'banner-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'banner-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own banner images
CREATE POLICY "Users can delete their own banner images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'banner-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================
-- ✅ STORAGE POLICIES COMPLETE!
-- ============================================

-- Test query to verify policies are created:
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';
