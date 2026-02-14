-- ============================================================================
-- QUICK FIX FOR EXISTING SUPPLIER
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Step 1: Check your supplier record
-- Replace 'YOUR_SUPPLIER_ID' with your actual supplier ID
SELECT 
  id,
  name,
  email,
  supplier_code,
  user_id,
  CASE 
    WHEN supplier_code IS NULL OR supplier_code = '' THEN '❌ NEEDS FIX'
    ELSE '✅ OK'
  END as supplier_code_status
FROM suppliers
WHERE id = 'YOUR_SUPPLIER_ID';

-- ============================================================================

-- Step 2: If supplier_code is NULL, assign one
-- Replace 'YOUR_SUPPLIER_ID' with your actual supplier ID

UPDATE suppliers
SET supplier_code = 'SUP0001'
WHERE id = 'YOUR_SUPPLIER_ID'
AND (supplier_code IS NULL OR supplier_code = '');

-- ============================================================================

-- Step 3: Verify the fix
SELECT 
  id,
  name,
  supplier_code,
  user_id
FROM suppliers
WHERE id = 'YOUR_SUPPLIER_ID';

-- Expected result: supplier_code should now be 'SUP0001'

-- ============================================================================

-- Step 4: Check if user_id is linked to auth.users
SELECT 
  s.id as supplier_id,
  s.name,
  s.supplier_code,
  s.user_id,
  u.email as auth_email,
  CASE 
    WHEN u.id IS NULL THEN '❌ user_id not linked to auth.users'
    ELSE '✅ Linked correctly'
  END as auth_status
FROM suppliers s
LEFT JOIN auth.users u ON s.user_id = u.id
WHERE s.id = 'YOUR_SUPPLIER_ID';

-- ============================================================================

-- Alternative: If you know your email, use this
-- Replace 'your@email.com' with your actual email

-- Check supplier by email
SELECT 
  id,
  name,
  email,
  supplier_code,
  user_id
FROM suppliers
WHERE email = 'your@email.com';

-- Fix supplier_code by email
UPDATE suppliers
SET supplier_code = 'SUP0001'
WHERE email = 'your@email.com'
AND (supplier_code IS NULL OR supplier_code = '');

-- ============================================================================

-- Alternative: Fix ALL suppliers with missing supplier_code
-- This will auto-generate codes for all suppliers

UPDATE suppliers
SET supplier_code = 'SUP' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0')
WHERE supplier_code IS NULL OR supplier_code = '';

-- This creates: SUP0001, SUP0002, SUP0003, etc.

-- ============================================================================

-- VERIFICATION: Check all suppliers
SELECT 
  id,
  name,
  email,
  supplier_code,
  user_id,
  CASE 
    WHEN supplier_code IS NULL OR supplier_code = '' THEN '❌ Still needs fix'
    ELSE '✅ Fixed!'
  END as status
FROM suppliers
ORDER BY created_at DESC;

-- All suppliers should show '✅ Fixed!'
