-- ============================================
-- Med Shakthi - Banners Table Setup
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste this → Run
-- ============================================

-- 1️⃣ CREATE BANNERS TABLE
CREATE TABLE IF NOT EXISTS banners (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  image_url TEXT NOT NULL,
  supplier_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  supplier_name TEXT,
  category TEXT NOT NULL CHECK (category IN ('Medicines', 'Devices', 'Health', 'Vitamins')),
  active BOOLEAN DEFAULT true,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2️⃣ CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_banners_active ON banners(active);
CREATE INDEX IF NOT EXISTS idx_banners_supplier_id ON banners(supplier_id);
CREATE INDEX IF NOT EXISTS idx_banners_category ON banners(category);
CREATE INDEX IF NOT EXISTS idx_banners_dates ON banners(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_banners_active_dates ON banners(active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_banners_created_at ON banners(created_at DESC);

-- 3️⃣ ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- 4️⃣ DROP EXISTING POLICIES (IF ANY)
DROP POLICY IF EXISTS "Anyone can read active banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can read own banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can insert own banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can update own banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can delete own banners" ON banners;

-- 5️⃣ CREATE RLS POLICIES

-- Policy: Anyone (authenticated) can read active, valid banners
CREATE POLICY "Anyone can read active banners"
ON banners FOR SELECT
USING (
  active = true 
  AND start_date <= NOW() 
  AND end_date >= NOW()
);

-- Policy: Suppliers can read ALL their own banners (active or not)
CREATE POLICY "Suppliers can read own banners"
ON banners FOR SELECT
USING (auth.uid() = supplier_id);

-- Policy: Suppliers can insert their own banners
CREATE POLICY "Suppliers can insert own banners"
ON banners FOR INSERT
WITH CHECK (auth.uid() = supplier_id);

-- Policy: Suppliers can update their own banners
CREATE POLICY "Suppliers can update own banners"
ON banners FOR UPDATE
USING (auth.uid() = supplier_id)
WITH CHECK (auth.uid() = supplier_id);

-- Policy: Suppliers can delete their own banners
ON banners FOR DELETE
USING (auth.uid() = supplier_id);

-- 6️⃣ CREATE FUNCTION TO AUTO-UPDATE updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7️⃣ CREATE TRIGGER FOR AUTO-UPDATE
DROP TRIGGER IF EXISTS update_banners_updated_at ON banners;
CREATE TRIGGER update_banners_updated_at
BEFORE UPDATE ON banners
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 8️⃣ CREATE FUNCTION TO AUTO-DISABLE EXPIRED BANNERS
CREATE OR REPLACE FUNCTION disable_expired_banners()
RETURNS void AS $$
BEGIN
  UPDATE banners
  SET active = false
  WHERE active = true
  AND end_date < NOW();
END;
$$ LANGUAGE plpgsql;

-- 9️⃣ ENABLE REALTIME FOR BANNERS TABLE
-- This allows .stream() to work in Flutter
-- Ensure the supabase_realtime publication exists and add the table to it.
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
    END IF;
END $$;
ALTER PUBLICATION supabase_realtime ADD TABLE banners;

-- ============================================
-- ✅ SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Go to Storage in Supabase Dashboard
-- 2. Create a bucket named: banner-images
-- 3. Set it to Public
-- 4. Run the storage policies below
-- ============================================

-- 📁 STORAGE BUCKET POLICIES
-- Run these AFTER creating the 'banner-images' bucket
-- ============================================

-- Note: You need to create the bucket first in the Supabase Dashboard:
-- Storage → New Bucket → Name: "banner-images" → Public: Yes

-- Then run these policies in SQL Editor:

-- Policy: Anyone can read banner images
-- CREATE POLICY "Anyone can read banner images"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'banner-images');

-- Policy: Authenticated users can upload to their own folder
-- CREATE POLICY "Users can upload to own folder"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--   bucket_id = 'banner-images' 
--   AND (storage.foldername(name))[1] = auth.uid()::text
-- );

-- Policy: Users can update their own images
-- CREATE POLICY "Users can update own images"
-- ON storage.objects FOR UPDATE
-- USING (
--   bucket_id = 'banner-images' 
--   AND (storage.foldername(name))[1] = auth.uid()::text
-- );

-- Policy: Users can delete their own images
-- CREATE POLICY "Users can delete own images"
-- ON storage.objects FOR DELETE
-- USING (
--   bucket_id = 'banner-images' 
--   AND (storage.foldername(name))[1] = auth.uid()::text
-- );

-- ============================================
-- 🧪 TEST QUERIES (OPTIONAL)
-- ============================================

-- Test: Insert a sample banner (replace with your user_id)
-- INSERT INTO banners (
--   title, 
--   subtitle, 
--   image_url, 
--   supplier_id, 
--   category, 
--   start_date, 
--   end_date
-- ) VALUES (
--   'LOWEST PRICES ARE LIVE',
--   'Up to 60% Off',
--   'https://via.placeholder.com/800x400',
--   'YOUR_USER_ID_HERE',
--   'Medicines',
--   NOW(),
--   NOW() + INTERVAL '7 days'
-- );

-- Test: View all banners
-- SELECT * FROM banners ORDER BY created_at DESC;

-- Test: View active banners
-- SELECT * FROM banners 
-- WHERE active = true 
-- AND start_date <= NOW() 
-- AND end_date >= NOW();

-- Test: Disable expired banners
-- SELECT disable_expired_banners();

-- ============================================
-- 📊 USEFUL QUERIES FOR MONITORING
-- ============================================

-- Count total banners
-- SELECT COUNT(*) as total_banners FROM banners;

-- Count active banners
-- SELECT COUNT(*) as active_banners FROM banners 
-- WHERE active = true AND start_date <= NOW() AND end_date >= NOW();

-- Count banners by category
-- SELECT category, COUNT(*) as count 
-- FROM banners 
-- GROUP BY category 
-- ORDER BY count DESC;

-- Count banners by supplier
-- SELECT supplier_id, supplier_name, COUNT(*) as banner_count 
-- FROM banners 
-- GROUP BY supplier_id, supplier_name 
-- ORDER BY banner_count DESC;

-- Find expired but still active banners
-- SELECT id, title, end_date 
-- FROM banners 
-- WHERE active = true AND end_date < NOW();

-- ============================================
-- ✅ ALL DONE!
-- ============================================
-- Your banners table is ready to use!
-- Next: Create the storage bucket and run the app
-- ============================================
