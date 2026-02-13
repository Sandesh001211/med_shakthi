# 🚀 Complete Supabase Setup Guide - From Scratch

## Step 1: Access Supabase Dashboard

1. **Open your browser**
2. **Go to**: https://supabase.com/dashboard
3. **Login** with your account
4. **Select your project**: `uizgfsvvomopgikylgfs` (or whatever your project name is)

---

## Step 2: Create the Banners Table

### **2.1 Open SQL Editor**
1. Click **"SQL Editor"** in the left sidebar
2. Click **"New Query"** button (top right)

### **2.2 Copy and Paste This SQL**

```sql
-- Create Banners Table
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

-- Create Indexes
CREATE INDEX IF NOT EXISTS idx_banners_active ON banners(active);
CREATE INDEX IF NOT EXISTS idx_banners_supplier_id ON banners(supplier_id);
CREATE INDEX IF NOT EXISTS idx_banners_category ON banners(category);

-- Enable Row Level Security
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Anyone can read active banners"
ON banners FOR SELECT
USING (active = true AND start_date <= NOW() AND end_date >= NOW());

CREATE POLICY "Suppliers can read own banners"
ON banners FOR SELECT
USING (auth.uid() = supplier_id);

CREATE POLICY "Suppliers can insert own banners"
ON banners FOR INSERT
WITH CHECK (auth.uid() = supplier_id);

CREATE POLICY "Suppliers can update own banners"
ON banners FOR UPDATE
USING (auth.uid() = supplier_id);

CREATE POLICY "Suppliers can delete own banners"
ON banners FOR DELETE
USING (auth.uid() = supplier_id);
```

### **2.3 Run the SQL**
1. Click **"Run"** button (or press Ctrl+Enter)
2. Wait for **"Success. No rows returned"** message
3. ✅ **Done!** Table created!

---

## Step 3: Verify Table Creation

1. Click **"Table Editor"** in the left sidebar
2. You should see **"banners"** in the list of tables
3. Click on it to see the columns

---

## Step 4: Create Storage Bucket

### **4.1 Go to Storage**
1. Click **"Storage"** in the left sidebar
2. Click **"New Bucket"** button

### **4.2 Create Bucket**
- **Name**: `banner-images`
- **Public bucket**: ✅ **CHECK THIS BOX** (very important!)
- Click **"Create bucket"**

### **4.3 Verify Bucket**
- You should see `banner-images` in the list
- It should show as **"Public"**

---

## Step 5: Set Storage Policies

### **5.1 Open Bucket Policies**
1. Click on **`banner-images`** bucket
2. Click **"Policies"** tab at the top
3. You'll see "No policies yet"

### **5.2 Create Policy 1: View Images**
1. Click **"New Policy"**
2. Choose **"For full customization"** → Click **"Get started"**
3. Fill in:
   - **Policy name**: `Anyone can view banner images`
   - **Allowed operation**: Check **"SELECT"** only
   - **Policy definition**: 
     ```sql
     true
     ```
4. Click **"Review"** → **"Save policy"**

### **5.3 Create Policy 2: Upload Images**
1. Click **"New Policy"** again
2. Choose **"For full customization"** → Click **"Get started"**
3. Fill in:
   - **Policy name**: `Authenticated users can upload`
   - **Allowed operation**: Check **"INSERT"** only
   - **Policy definition**:
     ```sql
     (auth.role() = 'authenticated'::text)
     ```
4. Click **"Review"** → **"Save policy"**

### **5.4 Create Policy 3: Delete Images**
1. Click **"New Policy"** again
2. Choose **"For full customization"** → Click **"Get started"**
3. Fill in:
   - **Policy name**: `Users can delete own images`
   - **Allowed operation**: Check **"DELETE"** only
   - **Policy definition**:
     ```sql
     ((storage.foldername(name))[1] = (auth.uid())::text)
     ```
4. Click **"Review"** → **"Save policy"**

### **5.5 Verify Policies**
- You should see **3 policies** listed
- ✅ **Done!** Storage is ready!

---

## Step 6: Enable Realtime (Optional but Recommended)

### **6.1 Go to Database Replication**
1. Click **"Database"** in the left sidebar
2. Click **"Replication"** tab

### **6.2 Enable Banners Table**
1. Find **"banners"** in the list
2. Toggle it **ON** (enable replication)
3. ✅ **Done!** Real-time enabled!

---

## Step 7: Test Everything

### **7.1 Check Table**
1. Go to **Table Editor** → **banners**
2. Should show empty table with all columns

### **7.2 Check Storage**
1. Go to **Storage** → **banner-images**
2. Should show empty bucket (ready for uploads)

### **7.3 Check Policies**
1. **Table policies**: Go to **Authentication** → **Policies** → Filter by "banners"
2. **Storage policies**: Go to **Storage** → **banner-images** → **Policies**

---

## ✅ Setup Complete!

You should now have:
- ✅ **Banners table** with RLS policies
- ✅ **Storage bucket** (`banner-images`) set to public
- ✅ **Storage policies** (view, upload, delete)
- ✅ **Realtime** enabled for banners table

---

## 🧪 Next: Test in Your App

1. **Open your app** (should already be running)
2. **Login as supplier**
3. **Go to Supplier Dashboard** → **Tap "Banners"**
4. **Tap "+" button** → **Create a banner**
5. **Upload image, fill form, publish**
6. **Check if it appears** in Manage Banners
7. **Login as client** → **Check home screen** → Should see banner!

---

## 🆘 Troubleshooting

### Issue: "Table already exists"
- **Solution**: Skip Step 2, table is already created

### Issue: "Bucket already exists"
- **Solution**: Skip Step 4.2, just set policies in Step 5

### Issue: "Upload fails with 403"
- **Solution**: Make sure you created ALL 3 storage policies in Step 5

### Issue: "Can't see banners on client side"
- **Solution**: Check that banner is:
  - Active = true
  - Start date ≤ today
  - End date ≥ today

---

## 📞 Need Help?

If you get stuck at any step, let me know which step number and I'll help you! 🚀
