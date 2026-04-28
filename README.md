# Katuya — Send it fast

> **by Silvio Lionel Nieva**

Katuya is an open-source, Uber-style delivery platform that connects **multi-tenant merchants** with **independent couriers** in real time. Built for **Android** and **Web**, with a powerful **Admin Panel**, real-time geo tracking, and a robust matching engine.

---

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Merchant App   │     │   Driver App    │     │  Admin Panel    │
│  (Flutter)      │     │   (Flutter)     │     │  (React+Vite)   │
│  Android + Web  │     │  Android + Web  │     │  Web            │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │      Firebase Auth    │                       │
         │      Cloud Firestore  │                       │
         │      FCM Messaging    │                       │
         │      Cloud Storage    │                       │
         └───────────────┬───────┴───────────────────────┘
                         │
              ┌──────────┴──────────┐
              │  Firebase Cloud     │
              │  Functions (Node)   │
              │  Express API +      │
              │  Firestore Triggers │
              └─────────────────────┘
```

### Data Flow — Order Lifecycle

```
Merchant creates order ──► Cloud Function: matching.ts ──► Geohash query
                                                    │
                                                    ▼
                                           FCM fan-out to drivers
                                                    │
                                                    ▼
Driver accepts offer ──► assignDriver ──► status: assigned ──► live tracking
                                                    │
              pickup ──► picked_up ──► delivered ──► payout
```

---

## Features

- **Multi-tenant**: Multiple merchants operate securely isolated on the same platform
- **Real-time tracking**: Live driver locations with ETA calculations
- **Smart matching**: Geohash-based nearest driver selection with offer fan-out
- **Push notifications**: FCM data messages for offers, status updates, and chat
- **Admin oversight**: Role management, live dashboards, manual intervention
- **I18n**: Spanish (es-AR) default + English support
- **Scalable**: Batched writes, composite indexes, fire-and-forget messaging
- **Observable**: Crashlytics, Performance Monitoring, structured logs

---

## Monorepo Structure

```
katuya/
├── apps/
│   ├── commerce_app/        # Merchant Flutter app (Android + Web)
│   ├── driver_app/          # Driver Flutter app (Android + Web)
│   └── admin_panel/         # Admin React app (Vite + Tailwind + shadcn/ui)
├── backend/
│   └── functions/           # Firebase Cloud Functions (TypeScript + Express)
├── packages/
│   ├── shared_models/       # Freezed Dart models
│   ├── shared_theme/        # Katuya brand colors & components
│   └── shared_utils/        # Firebase providers, location, validators
├── infra/
│   ├── firebase/            # firebase.json, rules, indexes
│   └── scripts/             # Seed, export, maintenance
├── docs/                    # Setup, run, deploy, security, extending
└── .github/workflows/       # CI/CD for Flutter builds + Firebase deploy
```

---

## Quick Start

### Prerequisites

- Flutter stable (3.x+) with Android SDK
- Node.js 20+
- Firebase CLI (`npm install -g firebase-tools`)
- Google Maps API key (Android + Web)
- Firebase project with Blaze plan (for Functions, Firestore, FCM)

### 1. Clone & Install

```bash
git clone https://github.com/your-org/katuya.git
cd katuya

# Backend
cd backend/functions && npm install

# Shared packages
for pkg in packages/*; do (cd "$pkg" && flutter pub get); done

# Apps
for app in apps/commerce_app apps/driver_app; do (cd "$app" && flutter pub get); done

# Admin Panel
cd apps/admin_panel && npm install
```

### 2. Configure Firebase

Place your configuration files:

```
apps/commerce_app/android/app/google-services.json
apps/driver_app/android/app/google-services.json
infra/firebase/firebase.json          # update project id
```

Set environment variables:

```bash
export FIREBASE_PROJECT_ID=katuya-xxxx
export GOOGLE_MAPS_API_KEY=your_key_here
```

### 3. Run Locally

```bash
# Start Firebase emulators
firebase emulators:start --only firestore,functions,auth

# In another terminal: seed data
node infra/scripts/seed.mjs --emulator

# Run merchant app
flutter run -d emulator-5554 apps/commerce_app

# Run driver app
flutter run -d emulator-5556 apps/driver_app

# Run admin panel
cd apps/admin_panel && npm run dev
```

See [`docs/setup.md`](docs/setup.md) and [`docs/run_local.md`](docs/run_local.md) for detailed instructions.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile / Web | Flutter 3.x (Dart) |
| Admin Panel | React 18, Vite, TypeScript, Tailwind CSS, shadcn/ui |
| Backend | Firebase Cloud Functions (Node.js 20, TypeScript, Express) |
| Database | Cloud Firestore |
| Auth | Firebase Authentication + Custom Claims |
| Messaging | Firebase Cloud Messaging (FCM) |
| Storage | Firebase Cloud Storage |
| Maps | Google Maps Flutter / Web SDK |
| CI/CD | GitHub Actions |

---

## Security

- **Tenant isolation**: Firestore Rules enforce `merchantId` boundaries
- **Role-based access**: Custom Claims (`admin`, `merchant`, `driver`)
- **Input validation**: Server-side validation on all HTTPS endpoints
- **Audit trail**: `orders.timeline` captures every state transition

See [`docs/security.md`](docs/security.md) for the complete security model.

---

## Documentation

- [`docs/setup.md`](docs/setup.md) — Firebase CLI, project setup, API keys
- [`docs/run_local.md`](docs/run_local.md) — Emulator suite, local development
- [`docs/deploy.md`](docs/deploy.md) — CI/CD secrets, environment promotion
- [`docs/security.md`](docs/security.md) — Roles, rules, threat model
- [`docs/extending.md`](docs/extending.md) — Pricing engine, multi-city, 3PL
- [`docs/api_reference.md`](docs/api_reference.md) — HTTPS API specification
- [`docs/architecture.md`](docs/architecture.md) — System diagrams, data flow

---

## Contributing

We use **Conventional Commits**:

```
feat: add order cancellation flow
fix: prevent duplicate driver assignment
docs: update emulator setup instructions
```

Please read [`CODEOWNERS`](CODEOWNERS) for reviewer assignments.

---

## License

MIT License — see [`LICENSE`](LICENSE).

> Crafted with precision in Argentina 🇦🇷  
> **by Silvio Lionel Nieva**
