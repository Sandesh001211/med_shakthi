-- ============================================================================
-- ENABLE SUPABASE REALTIME FOR SUPPLIER DASHBOARD
-- Run this in your Supabase SQL Editor to enable real-time updates
-- ============================================================================

-- Step 1: Enable Realtime for the tables
-- This allows Supabase to send real-time notifications when data changes

ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory;

-- Step 2: Verify Realtime is enabled
-- Run this to check which tables have realtime enabled

SELECT 
  schemaname,
  tablename
FROM 
  pg_publication_tables
WHERE 
  pubname = 'supabase_realtime'
  AND tablename IN ('orders', 'products', 'inventory');

-- Expected output:
-- schemaname | tablename
-- -----------+----------
-- public     | orders
-- public     | products
-- public     | inventory

-- ============================================================================
-- OPTIONAL: Create indexes for better real-time performance
-- ============================================================================

-- Index on orders.supplier_code for faster filtering
CREATE INDEX IF NOT EXISTS idx_orders_supplier_code 
ON orders(supplier_code);

-- Index on orders.created_at for date range queries
CREATE INDEX IF NOT EXISTS idx_orders_created_at 
ON orders(created_at DESC);

-- Index on products.supplier_code for faster filtering
CREATE INDEX IF NOT EXISTS idx_products_supplier_code 
ON products(supplier_code);

-- Index on inventory.supplier_id for faster filtering
CREATE INDEX IF NOT EXISTS idx_inventory_supplier_id 
ON inventory(supplier_id);

-- ============================================================================
-- VERIFY INDEXES
-- ============================================================================

SELECT 
  tablename,
  indexname,
  indexdef
FROM 
  pg_indexes
WHERE 
  schemaname = 'public'
  AND tablename IN ('orders', 'products', 'inventory')
ORDER BY 
  tablename, indexname;

-- ============================================================================
-- TEST REALTIME FUNCTIONALITY
-- ============================================================================

-- After running the above, test by inserting a test order:

-- INSERT INTO orders (
--   id,
--   user_id,
--   supplier_code,
--   product_id,
--   item_name,
--   price,
--   quantity,
--   total_amount,
--   status,
--   order_group_id
-- ) VALUES (
--   gen_random_uuid(),
--   'YOUR_CLIENT_USER_ID',
--   'YOUR_SUPPLIER_CODE',
--   'YOUR_PRODUCT_ID',
--   'Test Product',
--   100.00,
--   1,
--   100.00,
--   'pending',
--   gen_random_uuid()
-- );

-- If realtime is working, the supplier dashboard should update instantly!

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

-- If realtime is not working, check:

-- 1. Verify publication exists
SELECT * FROM pg_publication WHERE pubname = 'supabase_realtime';

-- 2. Check if tables are in publication
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

-- 3. Verify RLS policies allow SELECT
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual
FROM 
  pg_policies
WHERE 
  tablename IN ('orders', 'products', 'inventory');

-- ============================================================================
-- CLEANUP (if needed)
-- ============================================================================

-- To disable realtime (not recommended):
-- ALTER PUBLICATION supabase_realtime DROP TABLE orders;
-- ALTER PUBLICATION supabase_realtime DROP TABLE products;
-- ALTER PUBLICATION supabase_realtime DROP TABLE inventory;

-- ============================================================================
-- SUCCESS!
-- ============================================================================

-- If you see the tables listed in the verification query,
-- realtime is now enabled! 🎉
--
-- Your supplier dashboard will now update instantly when:
-- ✅ Clients place orders
-- ✅ Order status changes
-- ✅ Products are added/removed
-- ✅ Inventory levels change
