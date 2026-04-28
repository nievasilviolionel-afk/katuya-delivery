# Katuya — System Architecture

> **by Silvio Lionel Nieva**

## Overview

Katuya is an open-source, Uber-style delivery platform built with Firebase, Flutter, and React. It connects multi-tenant merchants with independent couriers in real time.

```
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Merchant App    │  │   Driver App     │  │  Admin Panel     │
│  (Flutter)       │  │   (Flutter)      │  │  (React + Vite)  │
│  Android + Web   │  │   Android + Web  │  │  Web             │
└──────┬───────────┘  └──────┬───────────┘  └──────┬───────────┘
       │                     │                     │
       └─────────────────────┼─────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │     Firebase Platform       │
              │  ┌─────────────────────┐    │
              │  │  Authentication     │    │
              │  │  Cloud Firestore    │    │
              │  │  Cloud Functions    │    │
              │  │  FCM Messaging      │    │
              │  │  Cloud Storage      │    │
              │  └─────────────────────┘    │
              └─────────────────────────────┘
```

## Data Flow — Order Lifecycle

```
1. CREATE        Merchant creates order via HTTPS API
                    ↓
2. TRIGGER       Firestore onCreate → Cloud Function
                    ↓
3. MATCH         Geohash query for online drivers
                    ↓
4. FAN-OUT       FCM data messages to top N drivers
                    ↓
5. ACCEPT        First driver to accept wins (atomic)
                    ↓
6. ASSIGN        Order status → assigned, driver → busy
                    ↓
7. TRACK         Live location updates every 5-10s
                    ↓
8. PICKUP        Driver marks as picked_up
                    ↓
9. DELIVER       Driver marks as delivered
                    ↓
10. PAYOUT       Automatic payout record created
```

## Matching Algorithm

1. **Geohash Bounding Box**: Query `drivers` where `online=true` AND `geohash` within 9-character range around merchant
2. **Distance Filter**: Haversine calculation to filter within delivery radius (default 5km)
3. **Sorting**: By distance, then by location recency
4. **Fan-out**: Create offer documents + FCM to top N (default 10)
5. **TTL**: Offers expire after 60 seconds
6. **Fallback**: Expand radius to 10km on retry, max 3 attempts

## Security Model

- **Tenant Isolation**: Firestore Rules enforce `merchantId` boundaries on all collections
- **Role-Based Access**: Firebase Custom Claims (admin, merchant, driver)
- **Input Validation**: Server-side on all HTTPS endpoints
- **Audit Trail**: `orders.timeline` captures every state transition

## Scalability Considerations

- Batched Firestore writes (500/doc batch)
- Composite indexes for common queries
- Fire-and-forget FCM messaging
- Geohash precision: 9 chars (~5m accuracy)
- Firebase Performance Monitoring integration
