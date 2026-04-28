# Katuya Project — Coordinator Execution Plan

> Brand: **Katuya** · Tagline: *Send it fast* · Signature: **by Silvio Lionel Nieva**

## 1. Dependency Analysis & Workstream Grouping

The 17 execution steps from the MASTER PROMPT are grouped into **7 workstreams** based on technology boundaries and dependency chains.

### Dependency Graph

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│ Workstream A│     │ Workstream B│     │  Workstream C   │
│ Foundation  │     │   Backend   │     │ Flutter Shared  │
│   (Infra)   │     │ (Functions) │     │  (Packages)     │
└──────┬──────┘     └──────┬──────┘     └────────┬────────┘
       │                   │                     │
       │         ┌─────────┴─────────┐          │
       │         │                   │          │
       ▼         ▼                   ▼          ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│ Workstream F│     │ Workstream D│     │  Workstream E   │
│Admin Panel  │     │Merchant App │     │   Driver App    │
│  (React)    │     │  (Flutter)  │     │   (Flutter)     │
└──────┬──────┘     └─────────────┘     └─────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│                    Workstream G                          │
│            CI/CD · Documentation · QA · Seed            │
└─────────────────────────────────────────────────────────┘
```

### Phase Execution

| Phase | Workstreams | Parallel? | Output |
|-------|-------------|-----------|--------|
| **1** | A + B + C | Yes (no inter-deps) | Repo skeleton, Firebase rules, backend scaffold, shared packages |
| **2** | D + E + F | Yes (D/E need C; F needs A+B) | Three complete applications |
| **3** | G | Sequential (needs all code) | CI/CD, docs, seed data, tests |
| **4** | Integration | Sequential | Merge verification, signature injection, final polish |

---

## 2. Workstream Sub-Prompts

---

### **Workstream A: Foundation & Infrastructure**
**Agent**: Infra Specialist  
**Dependencies**: None (entry point)  
**Deliverables**: All monorepo baseline files

**Sub-Prompt**:
```
You are building the foundation for Katuya — an Uber-style delivery platform.

GLOBAL CONTEXT:
- Brand: Katuya · Tagline: "Send it fast" · Signature: "by Silvio Lionel Nieva" (must appear in README, LICENSE header, and all generated templates)
- Stack: Firebase (Auth, Firestore, FCM, Storage), Flutter (Android + Web), React Admin, Node.js Cloud Functions
- Monorepo root: katuya/ with apps/, backend/, packages/, infra/
- Default locale: es-AR, currency: ARS, timezone: America/Argentina/Buenos_Aires
- License: MIT

TASK:
Create the complete monorepo skeleton with the following concrete deliverables:

1. Directory structure per section 2 of the master spec
2. README.md with architecture diagram (ASCII), setup instructions, brand signature
3. LICENSE (MIT) with "Copyright (c) 2024 Silvio Lionel Nieva"
4. .editorconfig, .gitignore (root-level, Flutter, Node, React), CODEOWNERS
5. infra/firebase/ containing:
   - firebase.json (hosting configs for admin_panel + web builds, functions, storage)
   - firestore.rules (production-hardened, multi-tenant isolation via merchantId + custom claims)
   - firestore.indexes.json (composite indexes for orders by status+merchantId+createdAt, drivers by online+geohash)
   - storage.rules (KYC document isolation)
6. GitHub Actions workflow skeletons:
   - .github/workflows/flutter_build.yml (build APKs on v* tags, upload to Releases)
   - .github/workflows/firebase_deploy.yml (deploy functions + hosting on main)
7. Generate brand assets: logo SVG, app icon concept, color palette (violet/teal + earthy Andean accents)

CONVENTIONS:
- Use placeholders: ${FIREBASE_PROJECT_ID}, ${GOOGLE_MAPS_API_KEY}
- All rules must have deny-by-default fallback
- Use conventional commits in any example commands
- File paths must match the monorepo structure exactly

EXPECTED OUTPUT:
- Complete file tree of katuya/ with all baseline files
- Full code for all configuration files listed above
- No hand-waving: every file must have concrete content
```

---

### **Workstream B: Backend Core**
**Agent**: Backend Engineer  
**Dependencies**: Workstream A (for firebase.json, rules structure) — can read A's output  
**Deliverables**: Complete Cloud Functions backend

**Sub-Prompt**:
```
You are building the backend for Katuya — an Uber-style delivery platform.

GLOBAL CONTEXT:
- Same as Workstream A
- Data model: Firestore collections users, merchants, drivers, orders, orderOffers, payouts, ratings, chats, notifications
- Roles: admin, merchant, driver via Firebase Custom Claims
- Matching algorithm: geohash-based nearest driver + FCM fan-out with TTL offers

TASK:
Implement the complete backend/functions/ directory with:

1. package.json — Node 20, TypeScript, Express, firebase-admin, firebase-functions, geofire-common, jest
2. tsconfig.json — strict, ES2020, outDir lib/
3. src/models.ts — TypeScript interfaces for all domain entities (UserProfile, Merchant, Driver, Order, Offer, TimelineEvent, Pricing, Location)
4. src/utils.ts — geohash helpers, distance calculation, idempotency checks, correlation ID logging
5. src/auth.ts — setCustomClaims (role + merchantId), validateRole middleware
6. src/fcm.ts — typed FCM senders (OrderOffer, OrderStatusUpdate, ChatMessage), multi-cast, error handling
7. src/matching.ts — complete matching algorithm:
   - onOrderCreated: query online drivers within merchant radius using geohash bounding box
   - sort by distance + location recency
   - fan-out FCM data messages to top N drivers
   - create offer documents with TTL
   - handle acceptOffer: first-accept wins, expire others, assign driver
   - handle timeout: expand radius or mark expired
   - edge cases: driver offline → auto-reassign, merchant cancel → notify
8. src/api.ts — Express mounted at /api:
   - POST /api/merchant/orders → create order (validate merchant claim)
   - POST /api/driver/accept → acceptOffer { orderId }
   - POST /api/driver/updateLocation → update lat/lng + geohash
   - POST /api/admin/setRole → assign role & merchantId (admin-only)
   - GET /api/merchant/orders?status=...
   - All endpoints with role guards, validation, structured logging
9. src/index.ts — exports HTTPS functions + Firestore triggers:
   - onCreate(orders/{id}) → invoke matching
   - onUpdate(orders/{id}) → state machine guards (created→searching→assigned→picked_up→delivered)
   - onWrite(drivers/{id}) → presence handling
10. __tests__/ — Jest tests for matching algorithm, role guards, state machine

CONVENTIONS:
- All functions use firebase-functions/v2 HTTPS callable and Firestore triggers
- Use admin.firestore.FieldValue.serverTimestamp() for all timestamps
- Idempotency: check order.timeline before state transitions
- Log format: { level, message, orderId?, merchantId?, driverId?, correlationId, timestamp }
- Placeholder: ${FIREBASE_PROJECT_ID} in any config references

EXPECTED OUTPUT:
- Complete backend/functions/ file tree
- Full TypeScript source code for all 9 files
- Working matching algorithm with geohash bounding box query logic
- Test file with at least 5 test cases covering matching + state transitions
```

---

### **Workstream C: Flutter Shared Packages**
**Agent**: Flutter Platform Engineer  
**Dependencies**: None (foundational packages)  
**Deliverables**: Three reusable Dart packages

**Sub-Prompt**:
```
You are building the shared Flutter packages for Katuya — an Uber-style delivery platform.

GLOBAL CONTEXT:
- Two Flutter apps: commerce_app (merchant) and driver_app (courier)
- State: Riverpod + freezed + json_serializable
- Firebase packages: core, auth, firestore, messaging, storage, crashlytics, performance
- Default locale: es-AR
- Brand colors: violet/teal + earthy Andean accents

TASK:
Create three packages under packages/:

1. packages/shared_models/:
   - pubspec.yaml with freezed, json_serializable, build_runner dependencies
   - lib/src/models.dart with Freezed classes:
     * UserProfile (role, merchantId, phone, email, displayName, photoUrl, driverStatus)
     * Merchant (name, legalName, taxId, address, geo, status, settings)
     * Driver (userId, vehicle, online, lastLocation, ratings, documents)
     * Order (merchantId, status, pickup, dropoff, pricing, assignedDriverId, etaSec, timeline)
     * Offer (driverId, state, sentAt)
     * Location (lat, lng, geohash, ts)
     * Pricing (base, distanceKm, timeMin, total, currency)
     * TimelineEvent (status, ts, by)
     * ChatMessage, Rating
   - All models with fromJson/toJson, copyWith, serverTimestamp handling
   - lib/shared_models.dart barrel export

2. packages/shared_theme/:
   - pubspec.yaml
   - lib/src/colors.dart — KatuyaColorScheme with primary violet, secondary teal, accent terracotta, semantic colors
   - lib/src/typography.dart — textTheme for Material 3 (display, headline, title, body, label)
   - lib/src/components.dart — KatuyaButton, KatuyaCard, KatuyaTextField, KatuyaAppBar, KatuyaStatusBadge styles
   - lib/shared_theme.dart barrel export
   - Include "by Silvio Lionel Nieva" in component doc comments

3. packages/shared_utils/:
   - pubspec.yaml
   - lib/src/firebase_providers.dart — Riverpod providers for FirebaseAuth, Firestore, Messaging, Storage instances
   - lib/src/location_utils.dart — geohash encode/decode wrapper, distance calculation, permission helpers
   - lib/src/date_utils.dart — es-AR date formatting, relative time
   - lib/src/validators.dart — phone AR format, email, required fields
   - lib/shared_utils.dart barrel export

CONVENTIONS:
- Use @freezed annotation with fromJson/toJson
- Use @JsonKey(includeFromJson: false, includeToJson: false) for Firestore DocumentReference fields
- All files under lib/src/, exported via barrel files
- Placeholder: ${GOOGLE_MAPS_API_KEY}

EXPECTED OUTPUT:
- Complete packages/shared_models/, packages/shared_theme/, packages/shared_utils/ file trees
- Full Dart code for all models, theme, and utility files
- Each package must be independently compilable (pubspec.yaml complete)
```

---

### **Workstream D: Merchant App**
**Agent**: Flutter App Engineer (Merchant)  
**Dependencies**: Workstream C (shared packages)  
**Deliverables**: Complete commerce_app

**Sub-Prompt**:
```
You are building the Merchant App for Katuya — an Uber-style delivery platform.

GLOBAL CONTEXT:
- App name: Katuya Comercio · Package: com.katuya.comercio
- Uses packages/shared_models, packages/shared_theme, packages/shared_utils
- State: Riverpod, Routing: go_router
- Firebase: auth (email+Google), Firestore, FCM, Crashlytics, Performance
- Maps: google_maps_flutter (Android), google_maps_flutter_web
- Default locale: es-AR, responsive for desktop web usage
- Signature: "by Silvio Lionel Nieva" in Splash and About

TASK:
Build apps/commerce_app/ as a production Flutter application:

1. pubspec.yaml — dependencies on all shared packages + firebase + maps + geolocator
2. android/app/ — AndroidManifest.xml with INTERNET, FCM, location permissions, Maps API key meta-data
3. lib/main.dart — entry point with ProviderScope, Firebase init, flavor-aware FirebaseOptions
4. lib/firebase_options.dart — dev/staging/prod FirebaseOptions placeholders
5. lib/router.dart — go_router routes: /splash → /auth → /home → /new-order → /order/:id → /settings → /about
6. lib/providers/ — auth_provider, orders_provider (stream from Firestore), selected_order_provider
7. lib/screens/:
   - splash_screen.dart — logo animation, tagline "Send it fast", "by Silvio Lionel Nieva"
   - auth_screen.dart — email/password + Google Sign-In, role validation (merchant)
   - home_screen.dart — orders list with filters (all/created/searching/assigned/delivered), pull-to-refresh
   - new_order_screen.dart — pickup (default = merchant address), dropoff form with map picker (lat/lng), notes, pricing preview
   - order_detail_screen.dart — live driver location map, timeline status, chat button, cancel action
   - settings_screen.dart — auto-assign toggle, delivery radius, cancel timeout, business hours
   - about_screen.dart — brand info, "by Silvio Lionel Nieva", version, license link
8. lib/services/ — order_service (create via HTTPS function), location_service
9. lib/widgets/ — order_card, status_chip, map_picker, chat_bubble

CONVENTIONS:
- Use shared_theme colors and components exclusively
- Order creation: call POST /api/merchant/orders then watch orders/{id} snapshot
- Live tracking: stream drivers/{assignedDriverId}.lastLocation, update map marker
- All user-facing strings in Spanish with i18n setup (flutter_localizations + intl)
- Placeholder google-services.json hookup

EXPECTED OUTPUT:
- Complete apps/commerce_app/ file tree
- Full Dart code for all screens, services, providers, router
- Working map picker integration
- Android manifest with all required permissions and FCM configuration
```

---

### **Workstream E: Driver App**
**Agent**: Flutter App Engineer (Driver)  
**Dependencies**: Workstream C (shared packages)  
**Deliverables**: Complete driver_app

**Sub-Prompt**:
```
You are building the Driver App for Katuya — an Uber-style delivery platform.

GLOBAL CONTEXT:
- App name: Katuya Repartidor · Package: com.katuya.repartidor
- Uses packages/shared_models, packages/shared_theme, packages/shared_utils
- State: Riverpod, Routing: go_router
- Firebase: auth (email+Google), Firestore, FCM, Crashlytics, Performance
- Maps: google_maps_flutter, geolocator for background location
- Default locale: es-AR
- Signature: "by Silvio Lionel Nieva" in Splash and About

TASK:
Build apps/driver_app/ as a production Flutter application:

1. pubspec.yaml — dependencies on all shared packages + firebase + maps + geolocator + flutter_foreground_task
2. android/app/ — AndroidManifest.xml with location (foreground + background), FCM, INTERNET, Maps API key
3. lib/main.dart — entry point, Firebase init, foreground service config
4. lib/firebase_options.dart — dev/staging/prod FirebaseOptions placeholders
5. lib/router.dart — routes: /splash → /auth → /home → /offer/:id → /order/:id → /earnings → /about
6. lib/providers/ — auth_provider, location_provider, offers_provider, earnings_provider
7. lib/screens/:
   - splash_screen.dart — logo, "Send it fast", "by Silvio Lionel Nieva"
   - auth_screen.dart — email/password + Google, driver onboarding (vehicle type, plate, DNI upload)
   - home_screen.dart — online/offline toggle, current status, nearby offers list, active order summary
   - offer_screen.dart — accept/decline with order details (pickup, dropoff, estimated earnings)
   - order_navigation_screen.dart — pickup/deliver action buttons, open Google Maps navigation intent (Android) / link (Web)
   - earnings_screen.dart — trip history, ratings display, weekly summary
   - about_screen.dart — brand info, signature, version
8. lib/services/:
   - location_service.dart — foreground service on Android, update every 5-10s when online+moving (min distance 15-30m), exponential backoff on failure, write to drivers/{id}.lastLocation and driverLocations/{id}/track/{ts}
   - offer_service.dart — listen to FCM data messages, display offers, call acceptOffer HTTPS function
9. lib/widgets/ — offer_card, earnings_tile, rating_stars

CONVENTIONS:
- Background location: use flutter_foreground_task or workmanager for persistent updates
- Do NOT spam updates when stationary (check distance from last update)
- FCM handler: onBackgroundMessage to show offer notifications even when app closed
- Driver online toggle writes drivers/{id}.online = true + lastLocation
- Accept flow: call POST /api/driver/accept, watch orders/{id} for assignment confirmation

EXPECTED OUTPUT:
- Complete apps/driver_app/ file tree
- Full Dart code for all screens, services, providers
- Working foreground location service with battery optimization
- FCM background message handler
- Android manifest with all location + FCM permissions
```

---

### **Workstream F: Admin Panel**
**Agent**: Frontend Engineer (React)  
**Dependencies**: Workstream A (for infra configs), Workstream B (for API contracts)  
**Deliverables**: Complete admin_panel React app

**Sub-Prompt**:
```
You are building the Admin Panel for Katuya — an Uber-style delivery platform.

GLOBAL CONTEXT:
- Stack: React 18 + Vite + TypeScript + Tailwind CSS + shadcn/ui
- Auth: Firebase Web SDK, require custom claim role=admin
- Data: TanStack Query for server state, TanStack Table for data grids
- Backend API: Firebase Cloud Functions Express API at /api
- Brand: Katuya, signature "by Silvio Lionel Nieva" in footer
- Default locale: es-AR

TASK:
Build apps/admin_panel/ as a production React application:

1. package.json — react, vite, typescript, tailwind, shadcn/ui, @tanstack/react-query, @tanstack/react-table, firebase, react-router-dom, recharts
2. tsconfig.json, vite.config.ts, tailwind.config.js, index.html
3. src/lib/firebase.ts — Firebase Web SDK init, auth instance, firestore instance, functions instance
4. src/lib/api.ts — typed API client for all backend endpoints (axios/fetch wrapper with auth headers)
5. src/components/ui/ — shadcn/ui components (Button, Card, Table, Dialog, Form, Input, Select, Badge, Avatar, Tabs, Sheet, Toast)
6. src/components/layout/ — Sidebar, Header, Footer (with "by Silvio Lionel Nieva"), PageHeader, DataTable
7. src/hooks/ — useAuth (require admin), useAdminGuard (redirect non-admins), useOrders, useDrivers, useMerchants
8. src/pages/:
   - LoginPage.tsx — Firebase email/password, redirect if not admin
   - DashboardPage.tsx — KPI cards (active drivers, orders today, avg ETA), charts with recharts, real-time order activity feed
   - MerchantsPage.tsx — CRUD table (name, legalName, taxId, status, radius, auto-assign), edit dialog, status toggle
   - DriversPage.tsx — table with presence indicator, document verification status, suspend/activate actions
   - OrdersPage.tsx — live order table with status filters, manual assign dropdown, force cancel button, order detail slide-out
   - SettingsPage.tsx — branding config, locale toggle, system parameters
9. src/App.tsx — router with protected routes, admin guard wrapper
10. src/main.tsx — entry point, QueryClientProvider, FirebaseAuthProvider
11. public/ — favicon, logo SVG, PWA manifest

CONVENTIONS:
- All API calls must include Firebase ID token in Authorization header
- Admin guard: check custom claims on mount, show loading state while verifying
- Tables: pagination, sorting, column visibility, export to CSV
- Use Spanish labels by default; English strings as fallback
- Responsive: sidebar collapses to hamburger on mobile

EXPECTED OUTPUT:
- Complete apps/admin_panel/ file tree
- Full TypeScript/React code for all components, pages, hooks
- Working routing with auth guards
- shadcn/ui components properly configured
- PWA manifest and favicon setup
```

---

### **Workstream G: CI/CD, Documentation, QA & Seed**
**Agent**: DevOps & QA Engineer  
**Dependencies**: All workstreams (needs code to build/test)  
**Deliverables**: CI/CD workflows, docs, seed script, test configs

**Sub-Prompt**:
```
You are building the DevOps, Documentation, and QA infrastructure for Katuya — an Uber-style delivery platform.

GLOBAL CONTEXT:
- Monorepo: katuya/ with apps/commerce_app, apps/driver_app, apps/admin_panel, backend/functions, packages/*
- CI/CD: GitHub Actions, Firebase CLI
- Default locale: es-AR
- Signature: "by Silvio Lionel Nieva" in all documentation footers

TASK:
Create the following under infra/ and docs/:

1. .github/workflows/flutter_build.yml:
   - Trigger on push tags v*
   - Setup Flutter stable, Java 17
   - Build APKs for both commerce_app and driver_app (flavor: prod)
   - Run flutter test for unit + widget tests
   - Upload APKs to GitHub Releases with release notes
   - Cache dependencies

2. .github/workflows/firebase_deploy.yml:
   - Trigger on push to main
   - Setup Node 20, Firebase CLI
   - Deploy functions (backend/functions/)
   - Deploy hosting (admin_panel build + any web build artifacts)
   - Deploy Firestore rules + indexes
   - Use firebase_service_account_json secret

3. .github/workflows/pr_checks.yml:
   - Run backend tests (jest)
   - Run Flutter analyze for both apps
   - Run admin_panel build (vite build)
   - Post coverage report

4. docs/:
   - setup.md — Firebase CLI install, project creation, emulator setup, Maps API key configuration
   - run_local.md — flutter run with emulator, functions emulator start, seed data script
   - deploy.md — CI/CD secrets, manual deployment steps, environment promotion
   - security.md — roles explanation, Firestore rules analysis, custom claims setup
   - extending.md — pricing engine, multi-city expansion, 3PL integration points
   - api_reference.md — all HTTPS endpoints with request/response examples
   - architecture.md — system diagram (ASCII or Mermaid), data flow, matching algorithm deep-dive

5. infra/scripts/seed.mjs:
   - Node.js script using firebase-admin
   - Create 5 sample merchants in Buenos Aires area
   - Create 10 sample drivers with vehicles and documents
   - Create 15 sample orders across all statuses
   - Use realistic Argentine addresses
   - Clear data option: --clean flag

6. infra/scripts/load_test.mjs:
   - Simulate 100 concurrent orders + 200 drivers
   - Measure assignment time p95
   - Report to stdout

7. Postman collection (docs/katuya_api.postman_collection.json):
   - All backend endpoints with example payloads
   - Environment variables for local/emulator/prod

CONVENTIONS:
- All docs in Markdown with table of contents
- Code blocks with language tags
- Placeholder values wrapped in ${...}
- Include "by Silvio Lionel Nieva" in footer of each doc page

EXPECTED OUTPUT:
- Complete .github/workflows/ with 3 workflow files
- Complete docs/ directory with 7 markdown files
- Complete infra/scripts/ with seed.mjs and load_test.mjs
- Postman collection JSON
```

---

## 3. Execution Order & Merge Strategy

### Phase 1: Foundation (Parallel)
| Workstream | Duration Estimate | Merge Target Branch |
|------------|-------------------|---------------------|
| A — Foundation | 1 cycle | `main` |
| B — Backend | 1 cycle | `main` |
| C — Shared Packages | 1 cycle | `main` |

**Merge Strategy**: Each workstream commits to a feature branch (`ws/a-infra`, `ws/b-backend`, `ws/c-shared`). A PR is opened to `main`. Since they touch disjoint directories (infra/, backend/, packages/), they can merge independently without conflicts.

### Phase 2: Applications (Parallel)
| Workstream | Duration Estimate | Merge Target |
|------------|-------------------|--------------|
| D — Merchant App | 1 cycle | `main` |
| E — Driver App | 1 cycle | `main` |
| F — Admin Panel | 1 cycle | `main` |

**Merge Strategy**: Feature branches (`ws/d-merchant`, `ws/e-driver`, `ws/f-admin`) merge to `main`. They depend on Phase 1 packages but only import them — no file overlap expected. CI must pass Flutter analyze / TS build before merge.

### Phase 3: DevOps & Docs (Sequential)
| Workstream | Duration Estimate | Merge Target |
|------------|-------------------|--------------|
| G — CI/CD + Docs | 1 cycle | `main` |

**Merge Strategy**: Branch `ws/g-devops` — touches `.github/workflows/` (new files), `docs/` (new), `infra/scripts/` (new). No conflicts with app code.

### Phase 4: Integration & Verification
**Integrator Tasks**:
1. Verify directory structure matches monorepo spec (section 2)
2. Check all files include "by Silvio Lionel Nieva" signature in splash/about/footer/LICENSE
3. Verify Firestore rules cover all collections with proper tenant isolation
4. Confirm backend API endpoints match what frontend apps call
5. Ensure shared_models JSON serialization matches Firestore document structure
6. Validate CI/CD workflows reference correct paths (apps/commerce_app, apps/driver_app, etc.)
7. Run `flutter analyze` for both apps (check for missing imports from shared packages)
8. Run `tsc --noEmit` in backend/functions and apps/admin_panel
9. Final commit: `chore(release): Katuya v1.0.0 — by Silvio Lionel Nieva`

---

## 4. Cross-Workstream Interface Contracts

### Backend API Contract
| Endpoint | Method | Auth | Request | Response |
|----------|--------|------|---------|----------|
| /api/merchant/orders | POST | Bearer {token} | {pickup, dropoff, notes} | {orderId, status} |
| /api/merchant/orders | GET | Bearer {token} | ?status=&merchantId= | Order[] |
| /api/driver/accept | POST | Bearer {token} | {orderId} | {success, assigned} |
| /api/driver/updateLocation | POST | Bearer {token} | {lat, lng} | {geohash} |
| /api/admin/setRole | POST | Bearer {token} | {uid, role, merchantId?} | {success} |

### Firestore Document Contracts
- `users/{uid}`: all apps read their own profile; admin reads all
- `drivers/{did}`: driver writes lastLocation; merchant reads online+location of assigned driver
- `orders/{oid}`: merchant creates/reads/updates own; driver reads/updates assigned; admin reads all
- `offers/{oid}`: backend creates; driver reads own; backend updates on accept/expire

### Package Import Contract
```yaml
# Both Flutter apps pubspec.yaml
dependencies:
  shared_models:
    path: ../../packages/shared_models
  shared_theme:
    path: ../../packages/shared_theme
  shared_utils:
    path: ../../packages/shared_utils
```

---

## 5. Risk Mitigation & Fallbacks

| Risk | Mitigation |
|------|------------|
| Missing Firebase project / API keys | Use `${PLACEHOLDER}` syntax; provide setup.md instructions |
| Geohash query performance | Use 9-character geohash precision (~5m); composite indexes in indexes.json |
| FCM delivery reliability | Implement offer TTL in Firestore; driver app polls offers/{driverId} as fallback |
| Background location killed by OS | Foreground service + persistent notification; exponential backoff; batched updates |
| Merchant web build issues | Responsive layouts via LayoutBuilder; test at 1280px+ |
| Admin Panel auth delay | Loading skeleton while Firebase auth initializes; admin claim check before route render |

---

*Coordinator Plan generated for Katuya — by Silvio Lionel Nieva*
