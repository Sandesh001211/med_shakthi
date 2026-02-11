# Banner System Architecture & Flow

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        BANNER SYSTEM                             │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────┐              ┌──────────────────────┐
│   SUPPLIER SIDE      │              │    CLIENT SIDE       │
│   (Admin/Seller)     │              │    (Customer)        │
└──────────────────────┘              └──────────────────────┘
         │                                      │
         │                                      │
         ▼                                      ▼
┌──────────────────────┐              ┌──────────────────────┐
│ Create Banner Screen │              │  Banner Carousel     │
│ Manage Banners Screen│              │  (Home Screen)       │
└──────────────────────┘              └──────────────────────┘
         │                                      │
         │                                      │
         └──────────────┬───────────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │  Banner Service  │
              │  (Business Logic)│
              └──────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │  Firebase Cloud  │
              │                  │
              │  • Firestore     │
              │  • Storage       │
              │  • Auth          │
              └──────────────────┘
```

---

## 🔄 Data Flow Diagram

### Supplier Flow: Create Banner

```
┌─────────────┐
│  Supplier   │
│  Opens      │
│  Create     │
│  Screen     │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ Fill Form:          │
│ • Upload Image      │
│ • Enter Title       │
│ • Enter Subtitle    │
│ • Select Category   │
│ • Set Dates         │
│ • Toggle Active     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Tap "Publish Offer" │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ BannerService       │
│ .createBanner()     │
└──────┬──────────────┘
       │
       ├──────────────────────┐
       │                      │
       ▼                      ▼
┌──────────────┐    ┌──────────────────┐
│ Upload Image │    │ Create Firestore │
│ to Storage   │    │ Document         │
└──────┬───────┘    └──────┬───────────┘
       │                   │
       ▼                   │
┌──────────────┐           │
│ Get Image URL│           │
└──────┬───────┘           │
       │                   │
       └────────┬──────────┘
                │
                ▼
      ┌──────────────────┐
      │ Save to Firestore│
      │ Collection:      │
      │ 'banners'        │
      └──────┬───────────┘
             │
             ▼
      ┌──────────────────┐
      │ Real-time Stream │
      │ Triggers Update  │
      └──────┬───────────┘
             │
             ▼
      ┌──────────────────┐
      │ All Clients See  │
      │ New Banner       │
      │ Automatically    │
      └──────────────────┘
```

### Client Flow: View Banners

```
┌─────────────┐
│  Customer   │
│  Opens      │
│  Home       │
│  Screen     │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ BannerCarousel      │
│ Widget Loads        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ StreamBuilder       │
│ Subscribes to       │
│ getActiveBanners    │
│ Stream()            │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Firestore Query:    │
│ • active = true     │
│ • startDate <= now  │
│ • endDate >= now    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Filter Valid        │
│ Banners             │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ PageView.builder    │
│ Renders Banners     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Auto-slide Timer    │
│ (Every 5 seconds)   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ User Taps Banner    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Navigate to         │
│ Category Products   │
└─────────────────────┘
```

---

## 🗂️ Component Hierarchy

### Supplier Side

```
ManageBannersScreen
├── AppBar
│   ├── Title: "Manage Banners"
│   └── Action: Add Button → CreateBannerScreen
│
├── StreamBuilder<List<BannerModel>>
│   ├── Loading State → CircularProgressIndicator
│   ├── Error State → Error Message
│   ├── Empty State → Empty State Widget
│   └── Data State → ListView.builder
│       └── BannerListItem (for each banner)
│           ├── Banner Preview Image
│           │   └── Status Badge (Active/Inactive/Expired)
│           ├── Banner Details
│           │   ├── Title
│           │   ├── Subtitle
│           │   ├── Info Chips (Category, Dates)
│           │   └── Action Buttons
│           │       ├── Toggle Active/Inactive
│           │       └── Delete Banner
│           └── Delete Confirmation Dialog
│
└── FloatingActionButton → CreateBannerScreen

CreateBannerScreen
├── AppBar
│   ├── Back Button
│   └── Title: "Create Offer"
│
├── Form (with validation)
│   ├── Image Upload Section
│   │   ├── Image Preview (if selected)
│   │   └── Upload Button (ImagePicker)
│   │
│   ├── Title Input Field
│   │   └── TextFormField (with validator)
│   │
│   ├── Subtitle Input Field
│   │   └── TextFormField (with validator)
│   │
│   ├── Category Dropdown
│   │   └── DropdownButtonFormField
│   │       └── Options: Medicines, Devices, Health, Vitamins
│   │
│   ├── Date Range Pickers
│   │   ├── Start Date Picker
│   │   └── End Date Picker
│   │
│   ├── Active Toggle
│   │   └── Switch Widget
│   │
│   └── Publish Button
│       └── Gradient Button → BannerService.createBanner()
│
└── Loading Overlay (during upload)
```

### Client Side

```
BannerCarousel
├── StreamBuilder<List<BannerModel>>
│   ├── Loading State → Shimmer/Skeleton
│   ├── Error State → Error Card
│   ├── Empty State → Placeholder Card
│   └── Data State
│       ├── PageView.builder
│       │   └── BannerCard (for each banner)
│       │       ├── Background Image (Network)
│       │       ├── Gradient Overlay
│       │       ├── Content Layer
│       │       │   ├── Category Tag
│       │       │   ├── Title (Bold, Large)
│       │       │   └── Subtitle
│       │       ├── Shopping Icon (Top Right)
│       │       └── GestureDetector → onBannerTap()
│       │
│       └── Page Indicators
│           └── Animated Dots (Active/Inactive)
│
└── Auto-scroll Timer
    └── Triggers pageController.animateToPage()
```

---

## 🔥 Firebase Structure

### Firestore Collection: `banners`

```
banners/
├── {bannerId1}
│   ├── id: "auto-generated"
│   ├── title: "LOWEST PRICES ARE LIVE"
│   ├── subtitle: "Up to 60% Off"
│   ├── imageUrl: "https://storage.googleapis.com/..."
│   ├── supplierId: "user123"
│   ├── supplierName: "MedCare Pharmacy"
│   ├── category: "Medicines"
│   ├── active: true
│   ├── startDate: Timestamp(2026-02-11)
│   ├── endDate: Timestamp(2026-02-18)
│   └── createdAt: Timestamp(2026-02-11)
│
├── {bannerId2}
│   ├── id: "auto-generated"
│   ├── title: "HEALTH WEEK SPECIAL"
│   ├── subtitle: "Buy 2 Get 1 Free"
│   ├── imageUrl: "https://storage.googleapis.com/..."
│   ├── supplierId: "user456"
│   ├── supplierName: "HealthPlus Store"
│   ├── category: "Health"
│   ├── active: true
│   ├── startDate: Timestamp(2026-02-15)
│   ├── endDate: Timestamp(2026-02-22)
│   └── createdAt: Timestamp(2026-02-15)
│
└── ...
```

### Firebase Storage: `banners/`

```
banners/
├── {supplierId1}/
│   ├── 1707667200000_user123.jpg
│   ├── 1707753600000_user123.jpg
│   └── ...
│
├── {supplierId2}/
│   ├── 1707840000000_user456.jpg
│   └── ...
│
└── ...
```

---

## 🔍 Query Patterns

### 1. Get Active Banners (Client Side)

```dart
_firestore
  .collection('banners')
  .where('active', isEqualTo: true)
  .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
  .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
  .orderBy('endDate', descending: false)
  .orderBy('createdAt', descending: true)
  .snapshots()
```

**Composite Index Required:**
- `active` (Ascending)
- `startDate` (Ascending)
- `endDate` (Ascending)
- `createdAt` (Descending)

### 2. Get Supplier's Banners (Supplier Side)

```dart
_firestore
  .collection('banners')
  .where('supplierId', isEqualTo: supplierId)
  .orderBy('createdAt', descending: true)
  .snapshots()
```

**Composite Index Required:**
- `supplierId` (Ascending)
- `createdAt` (Descending)

### 3. Get Banners by Category

```dart
_firestore
  .collection('banners')
  .where('category', isEqualTo: category)
  .where('active', isEqualTo: true)
  .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
  .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
  .orderBy('endDate', descending: false)
  .orderBy('createdAt', descending: true)
  .snapshots()
```

**Composite Index Required:**
- `category` (Ascending)
- `active` (Ascending)
- `startDate` (Ascending)
- `endDate` (Ascending)
- `createdAt` (Descending)

---

## ⚡ Real-Time Update Flow

```
┌──────────────────┐
│ Supplier creates │
│ or updates       │
│ banner           │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Firestore        │
│ document changes │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Firestore        │
│ triggers stream  │
│ event            │
└────────┬─────────┘
         │
         ├──────────────────┬──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ Client 1       │  │ Client 2       │  │ Client N       │
│ StreamBuilder  │  │ StreamBuilder  │  │ StreamBuilder  │
│ rebuilds       │  │ rebuilds       │  │ rebuilds       │
└────────┬───────┘  └────────┬───────┘  └────────┬───────┘
         │                   │                   │
         ▼                   ▼                   ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ UI updates     │  │ UI updates     │  │ UI updates     │
│ automatically  │  │ automatically  │  │ automatically  │
└────────────────┘  └────────────────┘  └────────────────┘
```

**No polling required!** Firestore streams provide real-time updates.

---

## 🎯 State Management

### Using StreamBuilder Pattern

```dart
StreamBuilder<List<BannerModel>>(
  stream: _bannerService.getActiveBannersStream(),
  builder: (context, snapshot) {
    // Connection State
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingWidget();
    }
    
    // Error State
    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error);
    }
    
    // Data State
    final banners = snapshot.data ?? [];
    
    if (banners.isEmpty) {
      return EmptyStateWidget();
    }
    
    return BannerListWidget(banners: banners);
  },
)
```

**Benefits:**
- ✅ Automatic UI updates
- ✅ Built-in loading states
- ✅ Error handling
- ✅ No manual state management
- ✅ Memory efficient

---

## 🔒 Security Rules

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /banners/{bannerId} {
      // Anyone can read active banners
      allow read: if request.auth != null;
      
      // Only suppliers can create banners
      allow create: if request.auth != null 
        && request.auth.uid == request.resource.data.supplierId;
      
      // Only the owner can update/delete
      allow update, delete: if request.auth != null 
        && request.auth.uid == resource.data.supplierId;
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /banners/{supplierId}/{fileName} {
      // Anyone can read
      allow read: if request.auth != null;
      
      // Only the supplier can write to their folder
      allow write: if request.auth != null 
        && request.auth.uid == supplierId;
    }
  }
}
```

---

## 📊 Performance Optimization

### 1. Image Optimization
- Compress images to 85% quality
- Max resolution: 1920x1080
- Use WebP format when possible

### 2. Query Optimization
- Use composite indexes
- Limit results with `.limit(10)`
- Order by most relevant fields first

### 3. Caching
- Firestore automatically caches data
- Images cached by Flutter's Image widget
- Use `CachedNetworkImage` for better control

### 4. Lazy Loading
- Only load visible banners
- Use PageView for efficient scrolling
- Dispose timers and controllers properly

---

## 🧪 Testing Strategy

### Unit Tests
- [ ] BannerModel serialization/deserialization
- [ ] Date validation logic
- [ ] Banner expiration logic

### Widget Tests
- [ ] BannerCarousel rendering
- [ ] CreateBannerScreen form validation
- [ ] ManageBannersScreen list display

### Integration Tests
- [ ] End-to-end banner creation flow
- [ ] Real-time updates
- [ ] Navigation flows

### Manual Testing
- [ ] Image upload with different formats
- [ ] Date picker edge cases
- [ ] Network error handling
- [ ] Auto-slide functionality

---

## 🚀 Deployment Checklist

- [ ] Firebase project configured
- [ ] Firestore indexes created
- [ ] Security rules deployed
- [ ] Storage rules deployed
- [ ] Dependencies installed
- [ ] Environment variables set
- [ ] Build tested on Android
- [ ] Build tested on iOS
- [ ] Performance profiled
- [ ] Analytics integrated (optional)

---

## 📈 Future Enhancements

### Phase 2
- [ ] Banner analytics (views, clicks, conversions)
- [ ] A/B testing support
- [ ] Scheduled publishing
- [ ] Banner templates

### Phase 3
- [ ] Video banners
- [ ] Interactive banners
- [ ] Personalized banners (based on user preferences)
- [ ] Multi-language support

### Phase 4
- [ ] AI-powered banner optimization
- [ ] Automated banner generation
- [ ] ROI tracking
- [ ] Advanced targeting

---

**Architecture Version:** 1.0  
**Last Updated:** February 2026  
**Maintained by:** Med Shakthi Development Team
