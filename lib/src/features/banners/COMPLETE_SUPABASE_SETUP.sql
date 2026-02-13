-- ============================================
-- Med Shakthi - Complete Banners Setup
-- ============================================
-- Copy this ENTIRE code and paste into Supabase SQL Editor
-- Then click RUN
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

-- 3️⃣ ENABLE ROW LEVEL SECURITY (RLS) ON BANNERS TABLE
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- 4️⃣ DROP EXISTING BANNER POLICIES (IF ANY)
DROP POLICY IF EXISTS "Anyone can read active banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can read own banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can insert own banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can update own banners" ON banners;
DROP POLICY IF EXISTS "Suppliers can delete own banners" ON banners;

-- 5️⃣ CREATE BANNER RLS POLICIES

-- Policy: Anyone can read active, valid banners
CREATE POLICY "Anyone can read active banners"
ON banners FOR SELECT
USING (
  active = true 
  AND start_date <= NOW() 
  AND end_date >= NOW()
);

-- Policy: Suppliers can read ALL their own banners
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
CREATE POLICY "Suppliers can delete own banners"
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

-- ============================================
-- STORAGE SETUP FOR BANNER IMAGES
-- ============================================

-- 9️⃣ ENABLE RLS ON STORAGE OBJECTS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 🔟 DROP EXISTING STORAGE POLICIES (IF ANY)
DROP POLICY IF EXISTS "Anyone can view banner images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload banner images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own banner images" ON storage.objects;

-- 1️⃣1️⃣ CREATE STORAGE POLICIES

-- Policy: Anyone can view banner images (public bucket)
CREATE POLICY "Anyone can view banner images"
ON storage.objects FOR SELECT
USING (bucket_id = 'banner-images');

-- Policy: Authenticated users can upload banner images
CREATE POLICY "Authenticated users can upload banner images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'banner-images' 
  AND auth.role() = 'authenticated'
);

-- Policy: Users can delete their own banner images
CREATE POLICY "Users can delete their own banner images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'banner-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================
-- ✅ SETUP COMPLETE!
-- ============================================
-- 
-- Next steps:
-- 1. Make sure you created the 'banner-images' storage bucket (public)
-- 2. Realtime should already be enabled for banners table
-- 3. Test by creating a banner in your app!
-- ============================================
