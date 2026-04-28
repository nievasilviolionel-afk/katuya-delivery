# Katuya — Setup Guide

> **by Silvio Lionel Nieva**

## Prerequisites

- Flutter SDK 3.x+ (with Android SDK)
- Node.js 20+ and npm
- Firebase CLI: `npm install -g firebase-tools`
- Google Cloud SDK (optional, for advanced operations)

## 1. Firebase Project Setup

```bash
# Login to Firebase
firebase login

# Create project (or use existing)
firebase projects:create katuya-prod

# Set as default
firebase use katuya-prod
```

### Enable Firebase Services

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Enable **Authentication** (Email/Password + Google)
3. Enable **Cloud Firestore** (start in locked mode)
4. Enable **Cloud Functions** (Blaze plan required)
5. Enable **Cloud Messaging**
6. Enable **Cloud Storage**

## 2. Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create API key with restrictions:
   - Android apps (add your app SHA-1)
   - Web apps (add your domain)
3. Enable APIs:
   - Maps SDK for Android
   - Maps JavaScript API
   - Geocoding API
   - Directions API

## 3. Environment Configuration

Create `.env` files:

```bash
# apps/commerce_app/.env
GOOGLE_MAPS_API_KEY=your_key_here

# apps/driver_app/.env  
GOOGLE_MAPS_API_KEY=your_key_here

# apps/admin_panel/.env
VITE_FIREBASE_API_KEY=your_web_api_key
VITE_FIREBASE_PROJECT_ID=katuya-prod
VITE_GOOGLE_MAPS_API_KEY=your_key_here
```

## 4. Install Dependencies

```bash
# Root
cd katuya

# Backend
cd backend/functions && npm install

# Shared packages
for pkg in packages/*; do (cd "$pkg" && flutter pub get); done

# Apps
for app in apps/commerce_app apps/driver_app; do
  (cd "$app" && flutter pub get)
done

# Admin Panel
cd apps/admin_panel && npm install
```

## 5. Configure Firebase Config Files

### apps/commerce_app/android/app/google-services.json

Download from Firebase Console → Project Settings → Your App → google-services.json

### apps/driver_app/android/app/google-services.json

Same process for the driver app.

## 6. Deploy Firestore Rules & Indexes

```bash
cd infra/firebase
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 7. Deploy Cloud Functions

```bash
cd backend/functions
npm run build
firebase deploy --only functions
```

## 8. Seed Initial Data

```bash
node infra/scripts/seed.mjs
```

This creates sample merchants and drivers in Buenos Aires.

---

**Next:** [Run Local Development](./run_local.md)
