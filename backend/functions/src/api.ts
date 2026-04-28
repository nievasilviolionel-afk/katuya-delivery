/**
 * Katuya Express API
 * by Silvio Lionel Nieva
 *
 * RESTful endpoints mounted at /api
 */

import * as express from 'express';
import * as admin from 'firebase-admin';
import * as cors from 'cors';
import * as helmet from 'helmet';
import rateLimit from 'express-rate-limit';

import { verifyAuth, requireRole, requireAdmin } from './auth';
import { acceptOffer, transitionOrderStatus, startMatching } from './matching';
import { sendStatusUpdate } from './fcm';
import {
  CreateOrderRequest,
  CreateOrderResponse,
  UpdateLocationRequest,
  UpdateLocationResponse,
  ListOrdersRequest,
  Order,
  OrderStatus,
} from './models';
import {
  encodeGeohash,
  structuredLog,
  generateCorrelationId,
  calculatePricing,
  estimateEtaSec,
} from './utils';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const app = express();

// Security middleware
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => (req as any).user?.uid || req.ip || 'anonymous',
});
app.use(apiLimiter);

// Attach correlation ID
app.use((req, res, next) => {
  (req as any).correlationId = req.headers['x-correlation-id'] as string || generateCorrelationId();
  next();
});

// ============================================
// Health Check
// ============================================
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'katuya-api',
    version: '1.0.0',
    author: 'Silvio Lionel Nieva',
    timestamp: new Date().toISOString(),
  });
});

// ============================================
// Merchant Routes
// ============================================

/**
 * POST /api/merchant/orders
 * Create a new delivery order
 */
app.post(
  '/api/merchant/orders',
  verifyAuth,
  requireRole('merchant'),
  async (req, res) => {
    const user = (req as any).user;
    const correlationId = (req as any).correlationId;

    try {
      const body = req.body as CreateOrderRequest;
      const merchantId = user.merchantId;

      if (!merchantId) {
        res.status(400).json({ error: 'Usuario no asociado a un comercio' });
        return;
      }

      // Validate required fields
      if (!body.dropoff || !body.dropoff.address || !body.dropoff.geo) {
        res.status(400).json({ error: 'Datos de entrega incompletos' });
        return;
      }

      // Get merchant for pickup defaults and pricing
      const merchantRef = db.collection('merchants').doc(merchantId);
      const merchantSnap = await merchantRef.get();

      if (!merchantSnap.exists) {
        res.status(400).json({ error: 'Comercio no encontrado' });
        return;
      }

      const merchantData = merchantSnap.data();
      const settings = merchantData?.settings || {};

      // Build pickup (default to merchant address)
      const pickup = body.pickup || {
        address: merchantData?.address || '',
        geo: merchantData?.geo || { lat: 0, lng: 0, geohash: '' },
      };

      // Calculate pricing
      const distanceKm = haversineDistanceKm(
        pickup.geo.lat,
        pickup.geo.lng,
        body.dropoff.geo.lat,
        body.dropoff.geo.lng
      );

      const timeMin = estimateEtaSec(distanceKm) / 60;
      const pricingCalc = calculatePricing(
        distanceKm,
        timeMin,
        settings.baseFare || 300,
        settings.perKmRate || 50,
        settings.perMinuteRate || 10,
        settings.minimumFare || 300
      );

      const pricing = {
        base: pricingCalc.base,
        distanceKm,
        timeMin,
        total: pricingCalc.total,
        currency: settings.currency || 'ARS',
      };

      // Create order document
      const orderRef = db.collection('orders').doc();
      const order: Omit<Order, 'id'> = {
        merchantId,
        createdBy: user.uid,
        status: 'created',
        pickup: pickup as any,
        dropoff: body.dropoff as any,
        pricing,
        timeline: [
          {
            status: 'created',
            ts: admin.firestore.FieldValue.serverTimestamp() as any,
            by: user.uid,
            note: body.notes || '',
          },
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp() as any,
        updatedAt: admin.firestore.FieldValue.serverTimestamp() as any,
      };

      await orderRef.set(order);

      structuredLog('info', 'Order created', {
        correlationId,
        orderId: orderRef.id,
        merchantId,
        userId: user.uid,
      });

      // Trigger matching asynchronously (don't block response)
      setImmediate(() => {
        startMatching(orderRef.id).catch((err) => {
          structuredLog('error', 'Async matching failed', {
            correlationId,
            orderId: orderRef.id,
            error: err.message,
          });
        });
      });

      res.status(201).json({
        orderId: orderRef.id,
        status: 'created',
        message: 'Orden creada exitosamente',
      } as CreateOrderResponse);
    } catch (err) {
      structuredLog('error', 'Create order failed', {
        correlationId,
        error: (err as Error).message,
        stack: (err as Error).stack,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

/**
 * GET /api/merchant/orders
 * List merchant orders with optional status filter
 */
app.get(
  '/api/merchant/orders',
  verifyAuth,
  requireRole('merchant'),
  async (req, res) => {
    const user = (req as any).user;
    const correlationId = (req as any).correlationId;
    const merchantId = user.merchantId;

    if (!merchantId) {
      res.status(400).json({ error: 'Usuario no asociado a un comercio' });
      return;
    }

    try {
      const queryParams = req.query as unknown as ListOrdersRequest;
      let query = db
        .collection('orders')
        .where('merchantId', '==', merchantId)
        .orderBy('createdAt', 'desc')
        .limit(queryParams.limit || 50);

      if (queryParams.status) {
        query = db
          .collection('orders')
          .where('merchantId', '==', merchantId)
          .where('status', '==', queryParams.status)
          .orderBy('createdAt', 'desc')
          .limit(queryParams.limit || 50);
      }

      const snapshot = await query.get();
      const orders = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      res.json({ orders, count: orders.length });
    } catch (err) {
      structuredLog('error', 'List orders failed', {
        correlationId,
        error: (err as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

/**
 * POST /api/merchant/orders/:id/cancel
 * Cancel an order
 */
app.post(
  '/api/merchant/orders/:id/cancel',
  verifyAuth,
  requireRole('merchant'),
  async (req, res) => {
    const user = (req as any).user;
    const correlationId = (req as any).correlationId;
    const orderId = req.params.id;

    try {
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        res.status(404).json({ error: 'Orden no encontrada' });
        return;
      }

      const order = orderSnap.data() as Order;
      if (order.merchantId !== user.merchantId) {
        res.status(403).json({ error: 'No autorizado para esta orden' });
        return;
      }

      const result = await transitionOrderStatus(
        orderId,
        'canceled',
        user.uid,
        'Cancelado por el comercio'
      );

      if (result.success) {
        res.json({ success: true, message: result.message });
      } else {
        res.status(400).json({ error: result.message });
      }
    } catch (err) {
      structuredLog('error', 'Cancel order failed', {
        correlationId,
        orderId,
        error: (err as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

// ============================================
// Driver Routes
// ============================================

/**
 * POST /api/driver/accept
 * Accept an order offer
 */
app.post(
  '/api/driver/accept',
  verifyAuth,
  requireRole('driver'),
  async (req, res) => {
    const user = (req as any).user;
    const correlationId = (req as any).correlationId;

    try {
      const { orderId } = req.body;
      if (!orderId) {
        res.status(400).json({ error: 'orderId requerido' });
        return;
      }

      const result = await acceptOffer(orderId, user.uid);

      structuredLog('info', 'Driver accept offer result', {
        correlationId,
        orderId,
        driverId: user.uid,
        result,
      });

      if (result.assigned) {
        res.json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (err) {
      structuredLog('error', 'Accept offer endpoint failed', {
        correlationId,
        error: (err as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

/**
 * POST /api/driver/updateLocation
 * Update driver current location
 */
app.post(
  '/api/driver/updateLocation',
  verifyAuth,
  requireRole('driver'),
  async (req, res) => {
    const user = (req as any).user;
    const correlationId = (req as any).correlationId;

    try {
      const body = req.body as UpdateLocationRequest;

      if (typeof body.lat !== 'number' || typeof body.lng !== 'number') {
        res.status(400).json({ error: 'lat y lng son requeridos y deben ser números' });
        return;
      }

      const geohash = encodeGeohash(body.lat, body.lng);

      const driverRef = db.collection('drivers').doc(user.uid);
      const driverSnap = await driverRef.get();

      if (!driverSnap.exists) {
        res.status(404).json({ error: 'Perfil de repartidor no encontrado' });
        return;
      }

      await driverRef.update({
        'lastLocation.lat': body.lat,
        'lastLocation.lng': body.lng,
        'lastLocation.geohash': geohash,
        'lastLocation.ts': admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Also write to history track subcollection (throttled in real app)
      const trackRef = driverRef.collection('track').doc();
      await trackRef.set({
        lat: body.lat,
        lng: body.lng,
        geohash,
        ts: admin.firestore.FieldValue.serverTimestamp(),
      });

      structuredLog('info', 'Driver location updated', {
        correlationId,
        driverId: user.uid,
        lat: body.lat,
        lng: body.lng,
        geohash,
      });

      res.json({
        geohash,
        updated: true,
      } as UpdateLocationResponse);
    } catch (err) {
      structuredLog('error', 'Update location failed', {
        correlationId,
        error: (err as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

/**
 * POST /api/driver/orders/:id/pickup
 * Mark order as picked up
 */
app.post(
  '/api/driver/orders/:id/pickup',
  verifyAuth,
  requireRole('driver'),
  async (req, res) => {
    const user = (req as any).user;
    const orderId = req.params.id;

    try {
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        res.status(404).json({ error: 'Orden no encontrada' });
        return;
      }

      const order = orderSnap.data() as Order;
      if (order.assignedDriverId !== user.uid) {
        res.status(403).json({ error: 'No autorizado para esta orden' });
        return;
      }

      const result = await transitionOrderStatus(
        orderId,
        'picked_up',
        user.uid,
        'Paquete retirado'
      );

      if (result.success) {
        res.json({ success: true, message: result.message });
      } else {
        res.status(400).json({ error: result.message });
      }
    } catch (err) {
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

/**
 * POST /api/driver/orders/:id/deliver
 * Mark order as delivered
 */
app.post(
  '/api/driver/orders/:id/deliver',
  verifyAuth,
  requireRole('driver'),
  async (req, res) => {
    const user = (req as any).user;
    const orderId = req.params.id;

    try {
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        res.status(404).json({ error: 'Orden no encontrada' });
        return;
      }

      const order = orderSnap.data() as Order;
      if (order.assignedDriverId !== user.uid) {
        res.status(403).json({ error: 'No autorizado para esta orden' });
        return;
      }

      const result = await transitionOrderStatus(
        orderId,
        'delivered',
        user.uid,
        'Entrega completada'
      );

      if (result.success) {
        res.json({ success: true, message: result.message });
      } else {
        res.status(400).json({ error: result.message });
      }
    } catch (err) {
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

// ============================================
// Admin Routes
// ============================================

/**
 * POST /api/admin/setRole
 * Assign role and merchantId to a user
 */
app.post(
  '/api/admin/setRole',
  verifyAuth,
  requireAdmin,
  async (req, res) => {
    const user = (req as any).user;
    const correlationId = (req as any).correlationId;

    try {
      const { setUserRole } = await import('./auth');
      await setUserRole(req, res);
    } catch (err) {
      structuredLog('error', 'Set role endpoint failed', {
        correlationId,
        error: (err as Error).message,
      });
      if (!res.headersSent) {
        res.status(500).json({ error: 'Error interno del servidor' });
      }
    }
  }
);

/**
 * GET /api/admin/orders
 * List all orders (admin only)
 */
app.get(
  '/api/admin/orders',
  verifyAuth,
  requireAdmin,
  async (req, res) => {
    const correlationId = (req as any).correlationId;

    try {
      const { status, limit = 100, offset = 0 } = req.query as {
        status?: string;
        limit?: string;
        offset?: string;
      };

      let query = db.collection('orders').orderBy('createdAt', 'desc').limit(Number(limit));

      if (status) {
        query = db
          .collection('orders')
          .where('status', '==', status)
          .orderBy('createdAt', 'desc')
          .limit(Number(limit));
      }

      const snapshot = await query.get();
      const orders = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      res.json({ orders, count: orders.length });
    } catch (err) {
      structuredLog('error', 'Admin list orders failed', {
        correlationId,
        error: (err as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
);

// ============================================
// Error Handler
// ============================================
app.use((err: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const correlationId = (req as any).correlationId || 'unknown';
  structuredLog('error', 'Unhandled API error', {
    correlationId,
    error: err.message,
    stack: err.stack,
  });
  res.status(500).json({ error: 'Internal server error', correlationId });
});

export { app };

// Helper for distance calculation
function haversineDistanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
