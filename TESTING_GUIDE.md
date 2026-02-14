# 🧪 SUPPLIER DASHBOARD TESTING GUIDE

## Quick Start - 3 Ways to Test

### ✅ **Method 1: Test with Existing Data (Easiest)**

If you already have a supplier account:

1. **Open Chrome** - The app is already running at `http://localhost:xxxxx`
2. **Login** with your supplier credentials
3. **View Dashboard** - You'll see real data from your database!

**What to Check:**
- ✅ Revenue shows your actual sales
- ✅ Pending orders count matches database
- ✅ Product count is correct
- ✅ Growth percentage is calculated
- ✅ Inventory alerts show low stock items

---

### 🎯 **Method 2: Add Test Data via Supabase (Recommended)**

**Step-by-Step:**

1. **Open Supabase Dashboard**
   - Go to: https://uizgfsvvomopgikylgfs.supabase.co
   - Login with your credentials

2. **Go to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run the Test Data Script**
   - Open the file: `test_data_insert.sql`
   - **IMPORTANT**: Replace these values first:
     ```sql
     'YOUR_USER_ID' → Your actual user_id from auth.users table
     'YOUR_CLIENT_USER_ID' → A client user_id for orders
     ```
   - Copy and paste the script
   - Click "Run" or press `Ctrl+Enter`

4. **Verify Data Inserted**
   - Run the verification queries at the bottom of the script
   - You should see:
     - 1 supplier (SUP001)
     - 5 products
     - 5 inventory records
     - 30 orders with various statuses

5. **Login and Test**
   - Go back to your app
   - Login with the supplier account
   - Dashboard should now show all the test data!

---

### 🔧 **Method 3: Manual Testing via Supabase UI**

**Add Data Manually:**

#### **Step 1: Create Supplier**
1. Go to Supabase → Table Editor → `suppliers`
2. Click "Insert" → "Insert row"
3. Fill in:
   - `name`: Test Supplier
   - `email`: test@supplier.com
   - `supplier_code`: SUP001
   - `user_id`: (your auth user ID)
   - `password`: (any test password)
4. Click "Save"

#### **Step 2: Add Products**
1. Go to `products` table
2. Add 3-5 products with:
   - `supplier_code`: SUP001
   - `name`: Product name
   - `price`: Any price (e.g., 100.00)
   - `sku`: Unique code (e.g., PROD001)
   - `expiry_date`: Future date

#### **Step 3: Add Inventory**
1. Go to `inventory` table
2. For each product, add:
   - `supplier_id`: (your supplier ID)
   - `product_id`: (product ID)
   - `stock_quantity`: (e.g., 50)

#### **Step 4: Add Orders**
1. Go to `orders` table
2. Add 5-10 orders with:
   - `supplier_code`: SUP001
   - `total_amount`: Any amount
   - `status`: Mix of pending, confirmed, delivered
   - `created_at`: Various dates this month

---

## 📊 What to Test on Dashboard

### **1. Revenue Card**
- ✅ Shows this month's revenue
- ✅ Growth percentage appears
- ✅ Green arrow for positive growth
- ✅ Red arrow for negative growth
- ✅ Numbers animate smoothly

### **2. Pending Orders Card**
- ✅ Shows count of pending orders
- ✅ Red twinkling badge if pending > 0
- ✅ "All Good" badge if pending = 0

### **3. Inventory Card**
- ✅ Shows total product count
- ✅ Alert badge for low stock items
- ✅ "Stock OK" if all items in stock

### **4. Customers Card**
- ✅ Shows unique customer count
- ✅ Badge shows total order count

### **5. Fulfillment Card**
- ✅ Shows delivery success rate %
- ✅ Badge shows delivered count

### **6. Average Order Card**
- ✅ Shows average order value
- ✅ Badge shows total order count

### **7. Growth Banner**
- ✅ Shows total revenue
- ✅ Growth indicator with icon
- ✅ "View Report" button works

---

## 🔍 Testing Scenarios

### **Scenario 1: New Supplier (No Data)**
**Expected:**
- All metrics show 0
- No alerts
- Clean empty state
- No errors

### **Scenario 2: Supplier with Pending Orders**
**Expected:**
- Pending count > 0
- Red twinkling "Action Needed" badge
- Alert is visible and pulsing

### **Scenario 3: Low Stock Items**
**Expected:**
- Inventory card shows alert
- Badge shows count of low stock items
- Orange/red alert badge

### **Scenario 4: Positive Growth**
**Expected:**
- Green growth percentage
- Up arrow icon
- Positive number with + prefix

### **Scenario 5: Negative Growth**
**Expected:**
- Red growth percentage
- Down arrow icon
- Negative number with - prefix

---

## 🐛 Troubleshooting

### **Problem: Dashboard shows all zeros**

**Possible Causes:**
1. No data in database
2. Supplier code mismatch
3. RLS policies blocking access

**Solutions:**
1. Run test data script
2. Verify `supplier_code` matches in all tables
3. Check Supabase RLS policies

---

### **Problem: "Failed to load dashboard data" error**

**Possible Causes:**
1. Database connection issue
2. Invalid supplier_code
3. Missing user_id

**Solutions:**
1. Check internet connection
2. Verify Supabase credentials in `.env`
3. Check supplier exists in database

---

### **Problem: Data not updating**

**Possible Causes:**
1. Auto-refresh disabled
2. Cache issue

**Solutions:**
1. Pull down to manually refresh
2. Restart the app
3. Clear browser cache

---

## 📱 Testing Checklist

Use this checklist to verify everything works:

- [ ] App loads without errors
- [ ] Login works with supplier credentials
- [ ] Dashboard displays (not blank)
- [ ] Revenue card shows correct amount
- [ ] Growth percentage calculates correctly
- [ ] Pending orders count is accurate
- [ ] Inventory count matches database
- [ ] Customer count is correct
- [ ] Fulfillment rate calculates properly
- [ ] Average order value is accurate
- [ ] Animations are smooth
- [ ] Alert badges appear when needed
- [ ] Pull-to-refresh works
- [ ] Auto-refresh updates data (wait 30 seconds)
- [ ] Theme toggle works (light/dark)
- [ ] "View Report" button navigates correctly
- [ ] No console errors in browser

---

## 🎯 Quick Test Commands

### **Check if data exists in Supabase:**

```sql
-- Check supplier
SELECT * FROM suppliers WHERE supplier_code = 'SUP001';

-- Check products
SELECT COUNT(*) FROM products WHERE supplier_code = 'SUP001';

-- Check orders
SELECT status, COUNT(*) FROM orders 
WHERE supplier_code = 'SUP001' 
GROUP BY status;

-- Check this month's revenue
SELECT SUM(total_amount) as revenue 
FROM orders 
WHERE supplier_code = 'SUP001' 
AND created_at >= date_trunc('month', CURRENT_DATE);
```

---

## 🚀 Expected Results

After adding test data, your dashboard should show:

- **Revenue**: ₹15,000 - ₹50,000 (varies)
- **Pending Orders**: 4-8 orders
- **Total Products**: 5 products
- **Customers**: 1-5 unique clients
- **Fulfillment Rate**: 60-80%
- **Average Order**: ₹500 - ₹2,000

---

## 💡 Pro Tips

1. **Use Chrome DevTools** (F12) to check for errors
2. **Check Network tab** to see API calls to Supabase
3. **Use Supabase Logs** to debug database queries
4. **Test in both light and dark mode**
5. **Test pull-to-refresh** by swiping down
6. **Wait 30 seconds** to see auto-refresh in action

---

## 📞 Need Help?

If you encounter issues:

1. Check browser console for errors (F12)
2. Verify Supabase connection in `.env` file
3. Check RLS policies in Supabase
4. Verify supplier_code matches across tables
5. Check that user_id exists in auth.users

---

**Happy Testing! 🎉**
