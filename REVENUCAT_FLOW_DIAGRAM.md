# 🔄 RevenueCat Purchase Flow - Visual Guide

## 📊 Complete Purchase Journey

### State 1: App Startup

```
┌─────────────────────────────────────────────────┐
│ main.dart - App Initialization                  │
├─────────────────────────────────────────────────┤
│                                                 │
│ 1. Load .env file                               │
│    └─ REVENUE_CAT_APP_STORE_KEY=appl_xxxx       │
│    └─ REVENUE_CAT_PLAY_STORE_KEY=xxxx           │
│                                                 │
│ 2. Call revenue_cat.initialize()                │
│    ├─ Platform key selected (iOS vs Android)    │
│    ├─ Purchases.configure() called              │
│    ├─ await loadCustomerInfo()  ✅              │
│    ├─ await loadOfferings()     ✅              │
│    └─ Listener registered                       │
│                                                 │
│ 3. Firebase.initializeApp()                     │
│                                                 │
│ 4. Running Firebase Auth restoration            │
│    └─ Listening for stored sessions...          │
│                                                 │
└─────────────────────────────────────────────────┘
```

### State 2: User Logged In (from previous session)

```
┌──────────────────────────────────────────────────────┐
│ AppInitializer._determineInitialRoute()              │
├──────────────────────────────────────────────────────┤
│                                                      │
│ ⚠️  CRITICAL POINT                                   │
│                                                      │
│ final user = await authService.authStateChanges     │
│               .first;                               │
│                                                      │
│ if (user != null) {                                 │
│   ✅ Sync with RevenueCat                           │
│   try {                                             │
│     await revenue_cat.login(user.uid);              │
│     print('✅ Synced: ${user.uid}')                 │
│   } catch (e) {                                     │
│     print('⚠️  Non-critical: $e')                   │
│     // Continue - user can still use the app        │
│   }                                                 │
│                                                      │
│   ✅ Now user is authenticated to both:            │
│   • Firebase (has session token)                   │
│   • RevenueCat (linked via UID)                    │
│                                                      │
│   Proceed to PIN check / home screen               │
│ }                                                   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### State 3: User Not Logged In → Login Screen

```
┌─────────────────────────────────────────────────┐
│ LoginScreen.dart                                │
├─────────────────────────────────────────────────┤
│ Options:                                        │
│ 1. Email/Password Login                         │
│ 2. Google Sign In                               │
│ 3. Apple Sign In                                │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ LoginViewModel.login() or signInWithGoogle()    │
├─────────────────────────────────────────────────┤
│                                                 │
│ 1. AuthService.signIn() / signInWithGoogle()    │
│    └─ Firebase Auth handles authentication      │
│       └─ Returns user with .uid                 │
│                                                 │
│ 2. ✅ Try-Catch: revenue_cat.login(user.uid)    │
│    ├─ Purchases.logIn(uid) called               │
│    ├─ RevenueCat server receives {              │
│    │   "user_id": "abc123xyz"                   │
│    │ }                                           │
│    │                                             │
│    ├─ RevenueCat looks up historical purchases  │
│    ├─ Returns active entitlements (if any)      │
│    │                                             │
│    └─ Continue even if error (non-blocking)     │
│                                                 │
│ 3. TrackingService().logLogin()                 │
│    ├─ Google Ads: record login event            │
│    ├─ Facebook SDK: record login event          │
│    └─ Set user ID for audience building         │
│                                                 │
│ 4. Navigate to PIN setup or home                │
│                                                 │
└─────────────────────────────────────────────────┘
```

### State 4: Browse Subscription Plans

```
┌──────────────────────────────────────────────────┐
│ SubscriptionScreen.dart                          │
├──────────────────────────────────────────────────┤
│ [Load Subscription Plans] button clicked         │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ SubscriptionViewModel.loadOfferings()            │
├──────────────────────────────────────────────────┤
│                                                  │
│ _isLoading = true                                │
│ notifyListeners() → Show loading spinner         │
│                                                  │
│ await _revenueCatService.loadOfferings()         │
│ └─ Purchases.getOfferings() call                 │
│    ├─ RevenueCat queries App Store Connect      │
│    ├─ Receives:                                  │
│    │  {                                          │
│    │    current: {                               │
│    │      identifier: "default",                │
│    │      packages: [                            │
│    │        {                                    │
│    │          identifier: "zen_pro_annual",      │
│    │          price: 99.99,                      │
│    │          priceString: "$99.99",             │
│    │          ...                                │
│    │        }                                    │
│    │      ]                                      │
│    │    }                                        │
│    │  }                                          │
│    └─ Stored in _offerings variable             │
│                                                  │
│ Get all packages:                                │
│ _revenueCatService.allAvailablePackages          │
│ └─ Returns aggregated list from all offerings   │
│                                                  │
│ _isLoading = false                               │
│ notifyListeners() → UI renders packages         │
│                                                  │
│ Default package pre-selected                     │
│                                                  │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ UI Renders:                                      │
├──────────────────────────────────────────────────┤
│                                                  │
│ ┌─────────────────────────────────────────────┐  │
│ │ ZEN BASIC                                   │  │
│ │ 100 invoices/month                          │  │
│ │ $9.99/month                                 │  │
│ │ [SELECT] [BUY NOW]                          │  │
│ └─────────────────────────────────────────────┘  │
│                                                  │
│ ┌─────────────────────────────────────────────┐  │
│ │ ZEN PRO                   ⭐ POPULAR         │  │
│ │ 300 invoices/month                          │  │
│ │ $99.99/year                                 │  │
│ │ [SELECT ✓] [BUY NOW]                        │  │
│ └─────────────────────────────────────────────┘  │
│                                                  │
│ ┌─────────────────────────────────────────────┐  │
│ │ ZEN ENTERPRISE                              │  │
│ │ Unlimited invoices                          │  │
│ │ Custom pricing                              │  │
│ │ [CONTACT SALES]                             │  │
│ └─────────────────────────────────────────────┘  │
│                                                  │
└──────────────────────────────────────────────────┘
```

### State 5: User Selects Plan

```
┌──────────────────────────────────────────────────┐
│ User taps on PRO plan [SELECT] button             │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ SubscriptionViewModel.selectPackage(package)     │
├──────────────────────────────────────────────────┤
│                                                  │
│ _selectedPackage = <zen_pro_annual package>      │
│ _errorMessage = null                             │
│                                                  │
│ TrackingService().logAddToCart()                 │
│ ├─ Google Ads: "add_to_cart" event              │
│ ├─ Facebook SDK: "AddedToCart" event            │
│ └─ Records: product ID, price, currency         │
│                                                  │
│ notifyListeners()                                │
│ └─ UI highlights selected plan                   │
│    └─ [SELECT ✓] button highlights              │
│                                                  │
└──────────────────────────────────────────────────┘
```

### State 6: User Initiates Purchase

```
┌──────────────────────────────────────────────────┐
│ User taps [BUY NOW] button on selected plan      │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ SubscriptionViewModel.purchaseSubscription()     │
├──────────────────────────────────────────────────┤
│                                                  │
│ _isLoading = true                                │
│ _errorMessage = null                             │
│ notifyListeners() → Show loading spinner         │
│                                                  │
│ if (_selectedPackage == null) {                  │
│   _errorMessage = 'No package selected'          │
│   return false                                   │
│ }                                                │
│                                                  │
│ Call RevenueCatService.purchasePackageObject()   │
│ └─ Pass the Package object                       │
│                                                  │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ RevenueCatService.purchasePackageObject()        │
├──────────────────────────────────────────────────┤
│                                                  │
│ try {                                            │
│   print('🛒 Attempting purchase:')               │
│   print('   Product: Zen Pro - Annual')          │
│   print('   Price: $99.99')                      │
│                                                  │
│   Purchases.purchasePackage(package)             │
│   └─ Hands off to native iOS                     │
│                                                  │
│ } catch (e) { ... detailed error handling ... } │
│                                                  │
└──────────────────────────────────────────────────┘
```

### State 7: App Store Payment Dialog

```
┌──────────────────────────────────────────────────┐
│ iOS System Dialog (Native)                       │
├──────────────────────────────────────────────────┤
│                                                  │
│ ╔════════════════════════════════════════════╗  │
│ ║ Complete your purchase on "Facture Zen"?  ║  │
│ ║                                            ║  │
│ ║ Zen Pro - Annual                           ║  │
│ ║ $99.99 billed once to your Apple Account  ║  │
│ ║                                            ║  │
│ ║ Your password and billing info are        ║  │
│ ║ secure, encrypted, and not shared with    ║  │
│ ║ Facture Zen.                               ║  │
│ ║                                            ║  │
│ ║ [Cancel]  [Manage]  [Buy]                 ║  │
│ ╚════════════════════════════════════════════╝  │
│                                                  │
│ User clicks [Buy]                                │
│ └─ Face ID / Touch ID / Passcode prompt         │
│    └─ User authenticates                        │
│                                                  │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ App Store Processes Payment                      │
├──────────────────────────────────────────────────┤
│                                                  │
│ 1. Charge user Apple Account: $99.99            │
│ 2. Create transaction record                     │
│ 3. Generate receipt with:                        │
│    ├─ Product ID: zen_pro_annual                │
│    ├─ Purchase date: 2026-03-05T10:30:00Z       │
│    ├─ Expiry date: 2027-03-05T10:30:00Z        │
│    ├─ Bundle ID: com.facturezen.app             │
│    └─ Cryptographic signature                   │
│                                                  │
│ 4. Send encrypted receipt to RevenueCat         │
│                                                  │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ RevenueCat Server Validates Receipt              │
├──────────────────────────────────────────────────┤
│                                                  │
│ 1. Decrypt receipt                               │
│ 2. Verify cryptographic signature                │
│ 3. Check transaction not fraudulent              │
│ 4. Activate entitlements:                        │
│    {                                             │
│      "zen_pro": {                                │
│        "expiresDate": "2027-03-05T10:30:00Z",   │
│        "rawData": {...},                         │
│        "isActive": true                          │
│      }                                           │
│    }                                             │
│ 5. Link to user UID (abc123xyz)                  │
│ 6. Store in RevenueCat database                  │
│                                                  │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ RevenueCat Returns PurchaseResult to App         │
├──────────────────────────────────────────────────┤
│                                                  │
│ PurchaseResult {                                 │
│   CustomerInfo {                                 │
│     entitlements: {                              │
│       active: {                                  │
│         "zen_pro": EntitlementInfo {             │
│           identifier: "zen_pro",                │
│           isActive: true,                       │
│           expiresDate: "2027-03-05T10:30:00Z",  │
│           ...                                    │
│         }                                        │
│       },                                         │
│       all: { ... all entitlements ... }         │
│     },                                           │
│     ...                                          │
│   }                                              │
│ }                                                │
│                                                  │
└──────────────────────────────────────────────────┘
```

### State 8: Purchase Success Handling

```
┌──────────────────────────────────────────────────┐
│ Back in subscription_view_model.dart             │
├──────────────────────────────────────────────────┤
│                                                  │
│ final success = result.customerInfo              │
│   .entitlements.active.isNotEmpty;               │
│                                                  │
│ if (success) {  ✅ Entitlements found!           │
│                                                  │
│   // 1️⃣  Track purchase for analytics           │
│   await TrackingService().logPurchase(           │
│     productId: 'zen_pro_annual',                 │
│     price: 99.99,                                │
│     currency: 'USD'                              │
│   )                                              │
│   ├─ Google Ads: "purchase" conversion           │
│   ├─ Facebook SDK: "Purchase" event              │
│   └─ Custom tracking: product attribution        │
│                                                  │
│   // 2️⃣  CRITICAL: Sync with Firebase           │
│   await _syncService.syncSubscriptionStatus()    │
│   │                                              │
│   └─ See "Firebase Sync" section below ⬇️        │
│                                                  │
│   // 3️⃣  UI shows success                       │
│   _errorMessage = null                           │
│   return true                                    │
│                                                  │
│ }                                                │
│                                                  │
└──────────────────────────────────────────────────┘
```

### State 9: Firebase Synchronization ⚡ CRITICAL

```
┌────────────────────────────────────────────────────┐
│ SubscriptionSyncService.syncSubscriptionStatus()   │
├────────────────────────────────────────────────────┤
│                                                    │
│ 1️⃣  Load fresh customer info from RevenueCat      │
│    await _revenueCatService.loadCustomerInfo()    │
│    └─ Purchases.getCustomerInfo()                 │
│       └─ Returns latest entitlements               │
│                                                    │
│ 2️⃣  Extract active entitlements                   │
│    final activeEntitlements =                     │
│      customerInfo.entitlements.active             │
│    └─ Result: {"zen_pro": EntitlementInfo(...)}   │
│                                                    │
│ 3️⃣  Find highest plan (if multiple)              │
│    Loop through entitlements and select best      │
│    └─ In this case: zen_pro (300 invoices/month) │
│                                                    │
│ 4️⃣  Update Firebase                              │
│    await _firebaseService.updateUserPlan(         │
│      isPremium: true,                             │
│      monthlyInvoiceLimit: 300,                    │
│      planName: "Zen Pro",                         │
│      allowedTemplatesCount: -1  ∞ unlimited       │
│    )                                              │
│                                                    │
│ 5️⃣  Firebase writes user document:               │
│    users/{uid}/subscription {                     │
│      "isPremium": true,                           │
│      "monthlyInvoiceLimit": 300,                  │
│      "planName": "Zen Pro",                       │
│      "allowedTemplatesCount": -1,                 │
│      "updatedAt": timestamp,                      │
│      "expiresAt": "2027-03-05T10:30:00Z"          │
│    }                                              │
│                                                    │
│ 6️⃣  After Firebase update:                       │
│    print('✅ User upgraded to: Zen Pro')          │
│    print('   Limit: 300 invoices/month')          │
│    print('   Templates: Unlimited')               │
│                                                    │
└────────────────────────────────────────────────────┘
```

### State 10: User Creates Invoice with New Features

```
┌─────────────────────────────────────────────┐
│ HomeSreen.dart - User clicks "New Invoice"  │
└─────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────┐
│ InvoiceCreationService                             │
├────────────────────────────────────────────────────┤
│                                                    │
│ 1️⃣  Check invoice limit for this month            │
│    subscriptionService.getCurrentPlan()           │
│    └─ Loads entitlements from RevenueCat          │
│    └─ Returns: SubscriptionPlan with limit=300    │
│                                                    │
│ invoicesCountThisMonth = 5                         │
│ if (invoicesCountThisMonth < 300) {               │
│   ✅ Can create invoice                            │
│ } else {                                           │
│   ❌ Limit reached → Show upgrade prompt           │
│ }                                                  │
│                                                    │
│ 2️⃣  Check template access                         │
│    subscriptionService.getAccessibleTemplates()   │
│    └─ Returns all templates (pro user)            │
│    └─ User can select from all options            │
│                                                    │
│ Template options available:                        │
│ ✅ Modern Template                                 │
│ ✅ Classic Template                                │
│ ✅ Minimal Template                                │
│ ✅ All others...                                   │
│                                                    │
│ 3️⃣  Create invoice with selected template         │
│    └─ Save to Firebase                            │
│    └─ Show success message                        │
│                                                    │
└────────────────────────────────────────────────────┘
```

### State 11: User Logs Out

```
┌──────────────────────────┐
│ User clicks "Log Out"     │
└──────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│ AuthService.signOut()                          │
├────────────────────────────────────────────────┤
│                                                │
│ try {                                          │
│   // 1️⃣  LOGOUT RevenueCat FIRST               │
│   try {                                        │
│     await revenue_cat.login(null)              │
│     print('✅ RevenueCat logged out')           │
│   } catch (e) {                                │
│     print('⚠️  RevenueCat logout failed')       │
│     // Non-blocking - continue anyway          │
│   }                                            │
│                                                │
│   // 2️⃣  THEN logout Firebase                 │
│   await Future.wait([                          │
│     _auth.signOut(),                           │
│     _googleSignIn.signOut()                    │
│   ])                                           │
│   print('✅ Firebase logged out')               │
│                                                │
│ } catch (e) {                                  │
│   print('❌ Logout error: $e')                  │
│ }                                              │
│                                                │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│ Result:                                        │
│                                                │
│ ✅ User logged out from:                       │
│   • Firebase (no session token)                │
│   • RevenueCat (no user ID linked)             │
│   • App (back to login screen)                 │
│                                                │
│ ✅ Next user can log in fresh                  │
│                                                │
└────────────────────────────────────────────────┘
```

---

## 🔄 State Machine Diagram

```
┌─────────────────────┐
│   NOT LOGGED IN     │
└────────┬────────────┘
         │
         │ User signs in (email/google/apple)
         │ + revenue_cat.login(uid) ✅
         │
         ▼
┌──────────────────────────────────────┐
│   LOGGED IN (No Subscription)        │
│   • Firebase: authenticated          │
│   • RevenueCat: synced with uid      │
│   • Entitlements: none               │
│   • Plan: Zen Gratuit (free)         │
│   • Limit: 3 invoices/month          │
└──────────┬─────────────────────────┬─┘
           │                         │
           │ Click "Buy"             │ User already has subscription
           │ → Show plans            │ (from previous version/device)
           │                         │
           ▼                         ▼
┌────────────────────────────────┐  ┌──────────────────────┐
│  PURCHASE INITIATED            │  │ SUBSCRIPTION RESTORED│
│  • Plans loaded from App Store │  │ • Log in triggers    │
│  • User selects plan           │  │   purchase restore   │
│  • User taps "Buy"             │  │ • Firebase synced    │
│  • App Store shows dialog      │  └──────────┬───────────┘
│  • User authenticates          │             │
│  • Payment processed           │             │
└────────────┬────────────────────┘             │
             │                                 │
             │ Payment successful              │
             │ + Firebase synced               │
             │                                 │
             ▼                                 │
        ┌──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────┐
│   LOGGED IN (With Subscription)          │
│   • Firebase: authenticated              │
│   • RevenueCat: synced with uid          │
│   • Entitlements: zen_pro                │
│   • Plan: Zen Pro                        │
│   • Limit: 300 invoices/month            │
│   • Templates: unlimited                 │
└──────────┬──────────────────────────────┬┘
           │                              │
           │ Create invoices              │ Subscription expires
           │ Use templates                │ or user downgrades
           │ Full access                  │
           │                              │
           │ User clicks "Log Out"        │
           │ revenue_cat.login(null) ✅   │
           │                              │
           ▼                              ▼
┌──────────────────────────────┐  ┌──────────────────────┐
│   NOT LOGGED IN              │  │  SUBSCRIPTION ENDED  │
│   (Clean state)              │  │  (Back to free plan) │
│   • Firebase: no session     │  │  (on next login)     │
│   • RevenueCat: no user      │  └──────────┬───────────┘
│   • Entitlements: cleared    │             │
│   • Home: login screen       │             │ User logs in again
│                              │             │
└──────────────────────────────┘             │
                                             │
                                             ▼
                                     ┌──────────────────────┐
                                     │ BACK TO STATE:       │
                                     │ "Logged In (Free)"   │
                                     │ 3 invoices/month     │
                                     └──────────────────────┘
```

---

## 🎯 Data Flow Overview

```
App Layer (Flutter)
│
├─ SubscriptionScreen (UI)
│  └─ Shows packages, handles user interaction
│
├─ SubscriptionViewModel (Logic)
│  ├─ selectPackage()
│  ├─ purchaseSubscription()
│  └─ notifyListeners()
│
└─ Services Layer
   │
   ├─ RevenueCatService (Wrapper)
   │  ├─ purchasePackageObject()
   │  ├─ loadOfferings()
   │  └─ Delegates to util
   │
   ├─ SubscriptionSyncService (Sync)
   │  ├─ syncSubscriptionStatus()
   │  ├─ getCurrentPlan()
   │  └─ Updates Firebase
   │
   └─ AuthService (Authentication)
      ├─ signIn() + revenue_cat.login()
      ├─ signOut() + revenue_cat.login(null)
      └─ Social logins + revenue_cat.login()
        
        ↓ Functions in revenue_cat_util.dart
        
External Services
│
├─ RevenueCat SDK
│  ├─ Purchases.configure()
│  ├─ Purchases.logIn(userId)
│  ├─ Purchases.purchasePackage()
│  ├─ Purchases.getOfferings()
│  ├─ Purchases.getCustomerInfo()
│  └─ Validates receipts server-side
│
├─ App Store Connect
│  ├─ Sells products
│  ├─ Processes payments
│  ├─ Sends receipts to RevenueCat
│  └─ Manages subscriptions
│
└─ Firebase
   ├─ Firebase Auth (authentication)
   ├─ Realtime Database
   │  └─ Stores user subscription data
   └─ Logging & Analytics
```

---

## 🐛 Error Recovery Flows

### Scenario: Network Error During Purchase

```
User purchases → Network error midway
           ↓
RevenueCat tries to reach App Store → FAILS
           ↓
PurchaseResult NOT returned (timeout)
           ↓
App catches exception:
  if (e.contains('NETWORK_ERROR')) {
    _errorMessage = 'Erreur réseau'
    return false
  }
           ↓
User sees: "Network error. Check connection."
           ↓
User retaps "Buy" after reconnecting
           ↓
App Store recognizes payment already received
           ↓
App Store delivers receipt to RevenueCat
           ↓
RevenueCat links purchase to user
           ↓
Next app startup auto-restores purchase
  revenue_cat.login(uid) in AppInitializer
           ↓
Firebase gets synced with subscription
```

### Scenario: User Buys on Device 2, Logs In on Device 1

```
User has:
• Device 2: Purchases "Zen Pro"
• Device 1: Wants to use same subscription

Device 1 - App starts:
  revenue_cat.login(same_uid)
           ↓
RevenueCat server checks: "Is this UID premium?"
           ↓
Finds: YES - zen_pro purchased on Device 2
           ↓
Returns CustomerInfo with active entitlements
           ↓
Firebase gets synced
           ↓
User on Device 1 has access to zen_pro features
```

---

## ✅ Verification Checklist

Use this to verify each component is working:

**RevenueCat Initialization:**
- [ ] Debug log: "RevenueCat initialized successfully"
- [ ] Debug log: "Offerings loaded: X offerings"
- [ ] Debug log: "Customer info loaded"

**Authentication:**
- [ ] Debug log: "User logged in: abc123xyz"
- [ ] Debug log: "RevenueCat synchronized with user: abc123xyz"

**Purchase:**
- [ ] Debug log: "🛒 Attempting purchase: zen_pro_annual"
- [ ] Debug log: "✅ Purchase successful!"
- [ ] Debug log: "Active entitlements: zen_pro"

**Firebase Sync:**
- [ ] Debug log: "🔄 Syncing subscription status..."
- [ ] Debug log: "📊 Active entitlements: zen_pro"
- [ ] Debug log: "✅ Firebase updated:"
- [ ] Check Firebase: users/{uid}/subscription has new data

**Logout:**
- [ ] Debug log: "✅ RevenueCat logged out"
- [ ] Debug log: "✅ Déconnexion réussie"

