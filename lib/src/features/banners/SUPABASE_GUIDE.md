# 🚀 Supabase Implementation Guide

## Overview
This guide shows you how to use **Supabase** instead of Firebase for the banner system. Supabase provides PostgreSQL database, real-time subscriptions, and file storage - all open-source!

---

## 📦 Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Supabase
  supabase_flutter: ^2.0.0
  
  # Image Picker
  image_picker: ^1.0.7
```

Run:
```bash
flutter pub get
```

---

## 🔧 Supabase Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note your **Project URL** and **Anon Key**

### 2. Initialize Supabase in Flutter

In your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(MyApp());
}
```

---

## 🗄️ Database Setup

### Create Banners Table

Run this SQL in Supabase SQL Editor:

```sql
-- Create banners table
CREATE TABLE banners (
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

-- Create indexes for better performance
CREATE INDEX idx_banners_active ON banners(active);
CREATE INDEX idx_banners_supplier_id ON banners(supplier_id);
CREATE INDEX idx_banners_category ON banners(category);
CREATE INDEX idx_banners_dates ON banners(start_date, end_date);
CREATE INDEX idx_banners_active_dates ON banners(active, start_date, end_date);

-- Enable Row Level Security (RLS)
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read active banners
CREATE POLICY "Anyone can read active banners"
ON banners FOR SELECT
USING (
  active = true 
  AND start_date <= NOW() 
  AND end_date >= NOW()
);

-- Policy: Suppliers can read their own banners
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

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
CREATE TRIGGER update_banners_updated_at
BEFORE UPDATE ON banners
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Function to auto-disable expired banners (optional, can be called via Edge Function)
CREATE OR REPLACE FUNCTION disable_expired_banners()
RETURNS void AS $$
BEGIN
  UPDATE banners
  SET active = false
  WHERE active = true
  AND end_date < NOW();
END;
$$ LANGUAGE plpgsql;
```

---

## 📁 Storage Setup

### Create Storage Bucket

1. Go to **Storage** in Supabase Dashboard
2. Create a new bucket named `banner-images`
3. Set it to **Public** (or configure policies)

### Storage Policies

Run this SQL:

```sql
-- Policy: Anyone can read banner images
CREATE POLICY "Anyone can read banner images"
ON storage.objects FOR SELECT
USING (bucket_id = 'banner-images');

-- Policy: Authenticated users can upload to their folder
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'banner-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can update their own images
CREATE POLICY "Users can update own images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'banner-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can delete their own images
CREATE POLICY "Users can delete own images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'banner-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

---

## 🔄 Real-Time Setup

Enable real-time for the banners table:

1. Go to **Database** → **Replication**
2. Enable replication for the `banners` table
3. This allows `.stream()` to work

Or run this SQL:

```sql
-- Enable real-time for banners table
ALTER PUBLICATION supabase_realtime ADD TABLE banners;
```

---

## 📝 Usage Examples

### Create Banner Screen (Supabase Version)

```dart
import 'package:med_shakthi/src/features/banners/services/banner_service_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _bannerService = BannerServiceSupabase();

Future<void> _publishBanner() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _bannerService.createBanner(
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      imageFile: _selectedImage!,
      supplierId: user.id,
      category: _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
      active: _isActive,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Banner published successfully!')),
    );
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Banner Carousel (Supabase Version)

```dart
import 'package:med_shakthi/src/features/banners/services/banner_service_supabase.dart';

final _bannerService = BannerServiceSupabase();

@override
Widget build(BuildContext context) {
  return StreamBuilder<List<BannerModel>>(
    stream: _bannerService.getActiveBannersStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }

      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      final banners = snapshot.data ?? [];
      
      if (banners.isEmpty) {
        return Text('No active banners');
      }

      return PageView.builder(
        itemCount: banners.length,
        itemBuilder: (context, index) {
          return BannerCard(banner: banners[index]);
        },
      );
    },
  );
}
```

---

## 🔐 Authentication

Make sure users are authenticated before creating banners:

```dart
// Check if user is logged in
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  // Redirect to login
  Navigator.pushNamed(context, '/login');
  return;
}

// Get user ID for supplier_id
final supplierId = user.id;
```

---

## 🎯 Key Differences from Firebase

| Feature | Firebase | Supabase |
|---------|----------|----------|
| **Database** | Firestore (NoSQL) | PostgreSQL (SQL) |
| **Real-time** | `.snapshots()` | `.stream()` |
| **Storage** | Firebase Storage | Supabase Storage |
| **Auth** | Firebase Auth | Supabase Auth |
| **Queries** | Collection queries | SQL queries |
| **Pricing** | Pay as you go | Free tier + paid |
| **Open Source** | No | Yes ✅ |

---

## 📊 Advantages of Supabase

✅ **Open Source** - Self-hostable  
✅ **PostgreSQL** - Powerful SQL database  
✅ **Real-time** - Built-in real-time subscriptions  
✅ **Row Level Security** - Fine-grained access control  
✅ **Free Tier** - Generous free tier  
✅ **SQL** - Full SQL power (joins, views, functions)  
✅ **Edge Functions** - Serverless functions  
✅ **Dashboard** - Great admin interface  

---

## 🔄 Migration from Firebase

If you already have Firebase code:

1. **Replace imports:**
   ```dart
   // Old
   import 'package:cloud_firestore/cloud_firestore.dart';
   
   // New
   import 'package:supabase_flutter/supabase_flutter.dart';
   ```

2. **Replace service:**
   ```dart
   // Old
   final _bannerService = BannerService();
   
   // New
   final _bannerService = BannerServiceSupabase();
   ```

3. **Update model imports:**
   ```dart
   // Old
   import '../models/banner_model.dart';
   
   // New
   import '../models/banner_model_supabase.dart';
   ```

---

## 🧪 Testing

### Test Real-time Updates

1. Open app in two devices/browsers
2. Create a banner on device 1
3. See it appear on device 2 automatically
4. Toggle active/inactive on device 1
5. See it update on device 2 in real-time

### Test Queries

```dart
// Get all active banners
final banners = await _bannerService.getActiveBanners();

// Get supplier's banners
final myBanners = await _bannerService
    .getSupplierBannersStream(supplierId)
    .first;

// Get banners by category
final medicineBanners = await _bannerService
    .getBannersByCategory('Medicines')
    .first;
```

---

## 🚀 Advanced Features

### Edge Functions for Auto-Expiration

Create a Supabase Edge Function to run daily:

```typescript
// supabase/functions/disable-expired-banners/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { error } = await supabase.rpc('disable_expired_banners')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

Schedule it with Supabase Cron or external service.

---

## 📞 Support

- **Supabase Docs**: https://supabase.com/docs
- **Flutter Package**: https://pub.dev/packages/supabase_flutter
- **Community**: https://github.com/supabase/supabase/discussions

---

## ✅ Checklist

- [ ] Create Supabase project
- [ ] Add credentials to `main.dart`
- [ ] Create `banners` table with SQL
- [ ] Set up Row Level Security policies
- [ ] Create `banner-images` storage bucket
- [ ] Set up storage policies
- [ ] Enable real-time replication
- [ ] Install `supabase_flutter` package
- [ ] Update service imports in your code
- [ ] Test banner creation
- [ ] Test real-time updates
- [ ] Test image upload

---

**Supabase Version:** 1.0  
**Status:** ✅ Ready to Use  
**Created:** February 2026
