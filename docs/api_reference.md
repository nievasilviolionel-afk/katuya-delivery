# Katuya — API Reference

> **by Silvio Lionel Nieva**

Base URL: `https://<region>-<project-id>.cloudfunctions.net/api`

## Authentication

All endpoints require a Firebase ID Token in the `Authorization` header:

```
Authorization: Bearer <id_token>
```

## Endpoints

### Merchant

#### POST `/api/merchant/orders`

Create a new delivery order.

**Request Body:**
```json
{
  "pickup": {
    "address": "Av. Corrientes 1234, Buenos Aires",
    "geo": { "lat": -34.6037, "lng": -58.3816 },
    "notes": "Tocar timbre"
  },
  "dropoff": {
    "name": "Juan Pérez",
    "phone": "+5491112345678",
    "address": "Av. Santa Fe 2000, Buenos Aires",
    "geo": { "lat": -34.5959, "lng": -58.3930 },
    "notes": "Departamento 3B"
  },
  "notes": "Fragile"
}
```

**Response:**
```json
{
  "orderId": "abc123",
  "status": "created",
  "message": "Orden creada exitosamente"
}
```

#### GET `/api/merchant/orders?status=<status>`

List merchant orders.

**Response:**
```json
{
  "orders": [...],
  "count": 42
}
```

#### POST `/api/merchant/orders/:id/cancel`

Cancel an order.

**Response:**
```json
{
  "success": true,
  "message": "Estado actualizado a: canceled"
}
```

### Driver

#### POST `/api/driver/accept`

Accept an order offer.

**Request Body:**
```json
{
  "orderId": "abc123"
}
```

**Response:**
```json
{
  "success": true,
  "assigned": true,
  "message": "Orden asignada exitosamente"
}
```

#### POST `/api/driver/updateLocation`

Update driver location.

**Request Body:**
```json
{
  "lat": -34.6037,
  "lng": -58.3816
}
```

**Response:**
```json
{
  "geohash": "69y7b",
  "updated": true
}
```

#### POST `/api/driver/orders/:id/pickup`

Mark order as picked up.

#### POST `/api/driver/orders/:id/deliver`

Mark order as delivered.

### Admin

#### POST `/api/admin/setRole`

Assign role to user.

**Request Body:**
```json
{
  "uid": "user123",
  "role": "merchant",
  "merchantId": "merchant456"
}
```

#### GET `/api/admin/orders?status=<status>&limit=<n>`

List all orders (admin only).

#### GET `/health`

Health check (no auth required).

**Response:**
```json
{
  "status": "ok",
  "service": "katuya-api",
  "version": "1.0.0",
  "author": "Silvio Lionel Nieva"
}
```
