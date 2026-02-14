-- ============================================================================
-- SUPPLIER DASHBOARD TEST DATA
-- Run this in your Supabase SQL Editor to create test data
-- ============================================================================

-- Step 1: Create a test supplier (if not exists)
-- Replace 'YOUR_USER_ID' with an actual auth.users ID from your Supabase Auth
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
  'YOUR_USER_ID', -- REPLACE THIS with your actual user_id from auth.users
  'Test Supplier Ltd',
  'test@supplier.com',
  '+91-9876543210',
  'SUP001',
  'Test Medical Supplies',
  'hashed_password_here',
  'VERIFIED'
) ON CONFLICT (supplier_code) DO NOTHING;

-- Get the supplier ID for reference
-- You'll need to replace 'SUP001' with your actual supplier_code

-- Step 2: Add test products
INSERT INTO products (
  id,
  name,
  generic_name,
  brand,
  sku,
  price,
  expiry_date,
  unit_size,
  category,
  supplier_code,
  image_url,
  sub_category
) VALUES 
  (gen_random_uuid(), 'Paracetamol 500mg', 'Acetaminophen', 'Crocin', 'MED001', 50.00, '2026-12-31', '10 tablets', 'Medicines', 'SUP001', 'https://via.placeholder.com/150', 'Pain Relief'),
  (gen_random_uuid(), 'Amoxicillin 250mg', 'Amoxicillin', 'Amoxil', 'MED002', 120.00, '2026-10-31', '10 capsules', 'Medicines', 'SUP001', 'https://via.placeholder.com/150', 'Antibiotics'),
  (gen_random_uuid(), 'Vitamin D3 1000IU', 'Cholecalciferol', 'HealthVit', 'VIT001', 250.00, '2027-06-30', '60 tablets', 'Vitamins', 'SUP001', 'https://via.placeholder.com/150', 'Supplements'),
  (gen_random_uuid(), 'Digital Thermometer', NULL, 'Omron', 'DEV001', 450.00, '2028-12-31', '1 unit', 'Devices', 'SUP001', 'https://via.placeholder.com/150', 'Diagnostic'),
  (gen_random_uuid(), 'Blood Pressure Monitor', NULL, 'Dr. Morepen', 'DEV002', 1500.00, '2028-12-31', '1 unit', 'Devices', 'SUP001', 'https://via.placeholder.com/150', 'Diagnostic')
ON CONFLICT (sku) DO NOTHING;

-- Step 3: Add inventory for these products
-- First, get the supplier_id
DO $$
DECLARE
  supplier_uuid uuid;
  product_record RECORD;
BEGIN
  -- Get supplier ID
  SELECT id INTO supplier_uuid FROM suppliers WHERE supplier_code = 'SUP001';
  
  -- Add inventory for each product
  FOR product_record IN 
    SELECT id FROM products WHERE supplier_code = 'SUP001'
  LOOP
    INSERT INTO inventory (
      id,
      product_id,
      supplier_id,
      stock_quantity,
      last_updated
    ) VALUES (
      gen_random_uuid(),
      product_record.id,
      supplier_uuid,
      floor(random() * 100 + 10)::int, -- Random stock between 10-110
      now()
    ) ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

-- Step 4: Add test orders
-- You'll need to replace 'YOUR_CLIENT_USER_ID' with an actual client user_id
DO $$
DECLARE
  supplier_uuid uuid;
  product_record RECORD;
  client_uuid uuid := 'YOUR_CLIENT_USER_ID'; -- REPLACE THIS
  order_group uuid;
  i int;
BEGIN
  -- Get supplier ID
  SELECT id INTO supplier_uuid FROM suppliers WHERE supplier_code = 'SUP001';
  
  -- Create orders for the last 3 months
  FOR i IN 1..30 LOOP
    order_group := gen_random_uuid();
    
    -- Get a random product
    SELECT id, name, brand, unit_size, image_url, price 
    INTO product_record 
    FROM products 
    WHERE supplier_code = 'SUP001' 
    ORDER BY random() 
    LIMIT 1;
    
    -- Create order
    INSERT INTO orders (
      id,
      user_id,
      supplier_id,
      supplier_code,
      product_id,
      item_name,
      brand,
      unit_size,
      image_url,
      price,
      quantity,
      total_amount,
      status,
      payment_status,
      order_group_id,
      created_at
    ) VALUES (
      gen_random_uuid(),
      client_uuid,
      supplier_uuid,
      'SUP001',
      product_record.id,
      product_record.name,
      product_record.brand,
      product_record.unit_size,
      product_record.image_url,
      product_record.price,
      floor(random() * 5 + 1)::int, -- Random quantity 1-5
      product_record.price * floor(random() * 5 + 1)::int,
      CASE 
        WHEN random() < 0.2 THEN 'pending'
        WHEN random() < 0.4 THEN 'confirmed'
        WHEN random() < 0.6 THEN 'shipped'
        ELSE 'delivered'
      END,
      CASE 
        WHEN random() < 0.9 THEN 'paid'
        ELSE 'pending'
      END,
      order_group,
      now() - (random() * interval '90 days') -- Random date in last 90 days
    );
  END LOOP;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- Run these to verify the data was inserted correctly
-- ============================================================================

-- Check supplier
SELECT * FROM suppliers WHERE supplier_code = 'SUP001';

-- Check products
SELECT COUNT(*) as product_count FROM products WHERE supplier_code = 'SUP001';

-- Check inventory
SELECT 
  p.name,
  i.stock_quantity
FROM inventory i
JOIN products p ON i.product_id = p.id
WHERE p.supplier_code = 'SUP001';

-- Check orders
SELECT 
  status,
  COUNT(*) as count,
  SUM(total_amount) as total_revenue
FROM orders 
WHERE supplier_code = 'SUP001'
GROUP BY status;

-- Check monthly revenue
SELECT 
  DATE_TRUNC('month', created_at) as month,
  COUNT(*) as order_count,
  SUM(total_amount) as revenue
FROM orders 
WHERE supplier_code = 'SUP001'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;
