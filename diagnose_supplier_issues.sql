-- ============================================================================
-- DIAGNOSTIC QUERIES FOR SUPPLIER DASHBOARD
-- Run these in Supabase SQL Editor to diagnose issues
-- ============================================================================

-- Step 1: Check if you have any suppliers in the database
SELECT 
  id,
  user_id,
  name,
  email,
  supplier_code,
  verification_status
FROM suppliers
ORDER BY created_at DESC
LIMIT 10;

-- Expected: You should see at least one supplier
-- If empty: You need to create a supplier account first

-- ============================================================================

-- Step 2: Check if supplier_code is set
SELECT 
  id,
  name,
  supplier_code,
  CASE 
    WHEN supplier_code IS NULL THEN '❌ NULL'
    WHEN supplier_code = '' THEN '❌ EMPTY'
    ELSE '✅ OK'
  END as status
FROM suppliers;

-- Expected: All suppliers should have status = '✅ OK'
-- If '❌ NULL' or '❌ EMPTY': Run the fix below

-- ============================================================================

-- Step 3: Check auth.users table
SELECT 
  id,
  email,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- Expected: You should see your user account
-- Note the user_id for next steps

-- ============================================================================

-- Step 4: Check if supplier is linked to auth user
SELECT 
  s.id as supplier_id,
  s.name as supplier_name,
  s.supplier_code,
  s.user_id,
  u.email as user_email
FROM suppliers s
LEFT JOIN auth.users u ON s.user_id = u.id
ORDER BY s.created_at DESC;

-- Expected: user_email should not be NULL
-- If NULL: supplier.user_id doesn't match any auth.users.id

-- ============================================================================

-- Step 5: Find suppliers with missing supplier_code
SELECT 
  id,
  name,
  email,
  supplier_code
FROM suppliers
WHERE supplier_code IS NULL OR supplier_code = '';

-- If any results: These suppliers need supplier_code assigned

-- ============================================================================
-- FIXES
-- ============================================================================

-- FIX 1: Generate supplier_code for suppliers that don't have one
UPDATE suppliers
SET supplier_code = 'SUP' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0')
WHERE supplier_code IS NULL OR supplier_code = '';

-- This will create codes like: SUP0001, SUP0002, SUP0003, etc.

-- ============================================================================

-- FIX 2: Link supplier to auth user (if user_id is NULL)
-- Replace 'YOUR_EMAIL' and 'YOUR_SUPPLIER_ID' with actual values

-- First, find your user_id
SELECT id, email FROM auth.users WHERE email = 'YOUR_EMAIL';

-- Then update supplier with that user_id
UPDATE suppliers
SET user_id = 'USER_ID_FROM_ABOVE'
WHERE id = 'YOUR_SUPPLIER_ID';

-- ============================================================================

-- FIX 3: Create a test supplier account
-- Replace values with your actual data

INSERT INTO suppliers (
  id,
  user_id,
  name,
  email,
  phone,
  supplier_code,
  company_name,
  password,
  verification_status
) VALUES (
  gen_random_uuid(),
  (SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL' LIMIT 1),
  'Test Supplier',
  'supplier@test.com',
  '+91-9876543210',
  'SUP0001',
  'Test Medical Supplies',
  'hashed_password',
  'VERIFIED'
) ON CONFLICT (supplier_code) DO NOTHING;

-- ============================================================================

-- VERIFICATION: Run this after fixes
SELECT 
  s.id,
  s.name,
  s.supplier_code,
  s.user_id,
  u.email,
  CASE 
    WHEN s.supplier_code IS NULL OR s.supplier_code = '' THEN '❌ Missing supplier_code'
    WHEN s.user_id IS NULL THEN '❌ Missing user_id'
    WHEN u.id IS NULL THEN '❌ Invalid user_id (no matching auth user)'
    ELSE '✅ All good!'
  END as status
FROM suppliers s
LEFT JOIN auth.users u ON s.user_id = u.id;

-- Expected: All rows should show '✅ All good!'

-- ============================================================================

-- QUICK TEST: Check if current logged-in user has a supplier account
-- Replace 'YOUR_USER_ID' with your actual auth.users.id

SELECT 
  s.*
FROM suppliers s
WHERE s.user_id = 'YOUR_USER_ID';

-- Expected: Should return one supplier record
-- If empty: You need to create a supplier account for this user

-- ============================================================================

-- Check products for a supplier
SELECT 
  COUNT(*) as product_count,
  supplier_code
FROM products
WHERE supplier_code = 'SUP0001'  -- Replace with your supplier_code
GROUP BY supplier_code;

-- ============================================================================

-- Check orders for a supplier
SELECT 
  COUNT(*) as order_count,
  SUM(total_amount) as total_revenue,
  supplier_code
FROM orders
WHERE supplier_code = 'SUP0001'  -- Replace with your supplier_code
GROUP BY supplier_code;

-- ============================================================================

-- Check inventory for a supplier
SELECT 
  COUNT(*) as inventory_count,
  SUM(stock_quantity) as total_stock,
  supplier_id
FROM inventory
WHERE supplier_id = (SELECT id FROM suppliers WHERE supplier_code = 'SUP0001')
GROUP BY supplier_id;

-- ============================================================================
-- SUMMARY
-- ============================================================================

-- Run this comprehensive check:
WITH supplier_check AS (
  SELECT 
    s.id,
    s.name,
    s.supplier_code,
    s.user_id,
    u.email,
    (SELECT COUNT(*) FROM products WHERE supplier_code = s.supplier_code) as product_count,
    (SELECT COUNT(*) FROM orders WHERE supplier_code = s.supplier_code) as order_count,
    (SELECT SUM(total_amount) FROM orders WHERE supplier_code = s.supplier_code) as total_revenue,
    (SELECT COUNT(*) FROM inventory WHERE supplier_id = s.id) as inventory_count
  FROM suppliers s
  LEFT JOIN auth.users u ON s.user_id = u.id
)
SELECT 
  *,
  CASE 
    WHEN supplier_code IS NULL THEN '❌ Fix: Add supplier_code'
    WHEN user_id IS NULL THEN '❌ Fix: Link to auth user'
    WHEN email IS NULL THEN '❌ Fix: Invalid user_id'
    WHEN product_count = 0 THEN '⚠️ Warning: No products'
    WHEN order_count = 0 THEN '⚠️ Warning: No orders'
    ELSE '✅ Ready to use!'
  END as status
FROM supplier_check;

-- This will show you exactly what's missing!
