/**
 * Katuya Matching Algorithm
 * by Silvio Lionel Nieva
 *
 * Geohash-based nearest driver selection with offer fan-out and TTL handling.
 */

import * as admin from 'firebase-admin';
import { getGeohashRange } from 'geofire-common';
import {
  Order,
  OrderStatus,
  Offer,
  OfferState,
  Driver,
  Merchant,
  GeoPoint,
} from './models';
import {
  encodeGeohash,
  haversineDistance,
  structuredLog,
  isValidStateTransition,
  estimateEtaSec,
  calculatePricing,
  sleep,
} from './utils';
import { sendOrderOffers, sendStatusUpdate } from './fcm';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const DEFAULT_FANOUT_COUNT = 10;
const DEFAULT_OFFER_TTL_SECONDS = 60;
const DEFAULT_MATCHING_RADIUS_KM = 5;
const EXPANDED_RADIUS_KM = 10;
const MAX_MATCHING_ATTEMPTS = 3;

/**
 * Main entry: called when a new order is created (Firestore onCreate trigger)
 */
export async function startMatching(orderId: string): Promise<void> {
  const correlationId = `match-${orderId}-${Date.now()}`;

  structuredLog('info', 'Starting matching process', {
    correlationId,
    orderId,
  });

  try {
    const orderRef = db.collection('orders').doc(orderId);
    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      structuredLog('error', 'Order not found for matching', { correlationId, orderId });
      return;
    }

    const order = { id: orderSnap.id, ...orderSnap.data() } as Order;

    // Validate state
    if (order.status !== 'created') {
      structuredLog('warn', 'Order not in created state, skipping matching', {
        correlationId,
        orderId,
        status: order.status,
      });
      return;
    }

    // Transition to searching
    await orderRef.update({
      status: 'searching' as OrderStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      timeline: admin.firestore.FieldValue.arrayUnion({
        status: 'searching',
        ts: admin.firestore.FieldValue.serverTimestamp(),
        by: 'system',
        note: 'Matching started',
      }),
    });

    // Get merchant details for radius
    const merchantRef = db.collection('merchants').doc(order.merchantId);
    const merchantSnap = await merchantRef.get();
    const merchant = merchantSnap.exists
      ? ({ id: merchantSnap.id, ...merchantSnap.data() } as Merchant)
      : null;

    const radiusKm = merchant?.settings?.deliveryRadiusKm ?? DEFAULT_MATCHING_RADIUS_KM;

    // Find and assign driver
    await findAndAssignDriver(order, merchant, radiusKm, correlationId);

  } catch (err) {
    structuredLog('error', 'Matching process failed', {
      correlationId,
      orderId,
      error: (err as Error).message,
      stack: (err as Error).stack,
    });
  }
}

/**
 * Find online drivers within radius and send offers
 */
async function findAndAssignDriver(
  order: Order,
  merchant: Merchant | null,
  radiusKm: number,
  correlationId: string,
  attempt = 1
): Promise<void> {
  const pickupGeo = order.pickup.geo;

  structuredLog('info', 'Searching for drivers', {
    correlationId,
    orderId: order.id,
    radiusKm,
    attempt,
  });

  // Query online drivers using geohash ranges
  const ranges = getGeohashRange([pickupGeo.lat, pickupGeo.lng], radiusKm * 1000);
  const onlineDrivers: Array<Driver & { distanceKm: number; fcmToken?: string }> = [];

  for (const range of ranges) {
    const driversSnapshot = await db
      .collection('drivers')
      .where('online', '==', true)
      .where('lastLocation.geohash', '>=', range.start)
      .where('lastLocation.geohash', '<=', range.end)
      .limit(50)
      .get();

    for (const doc of driversSnapshot.docs) {
      const driver = { id: doc.id, ...doc.data() } as Driver;

      // Skip if driver is busy or suspended
      if (!driver.online || !driver.lastLocation) continue;

      const distanceKm = haversineDistance(
        pickupGeo.lat,
        pickupGeo.lng,
        driver.lastLocation.lat,
        driver.lastLocation.lng
      );

      if (distanceKm <= radiusKm) {
        // Get FCM token from user document
        const userSnap = await db.collection('users').doc(driver.userId).get();
        const userData = userSnap.data();
        onlineDrivers.push({
          ...driver,
          distanceKm,
          fcmToken: userData?.fcmToken as string | undefined,
        });
      }
    }
  }

  // Sort by distance and location recency
  onlineDrivers.sort((a, b) => {
    const distDiff = a.distanceKm - b.distanceKm;
    if (Math.abs(distDiff) > 0.5) return distDiff;
    // If similar distance, prefer more recent location update
    const aTs = a.lastLocation?.ts ? (a.lastLocation.ts as any).toMillis?.() || Date.now() : 0;
    const bTs = b.lastLocation?.ts ? (b.lastLocation.ts as any).toMillis?.() || Date.now() : 0;
    return bTs - aTs;
  });

  if (onlineDrivers.length === 0) {
    structuredLog('warn', 'No online drivers found', {
      correlationId,
      orderId: order.id,
      radiusKm,
      attempt,
    });

    if (attempt < MAX_MATCHING_ATTEMPTS && radiusKm < EXPANDED_RADIUS_KM) {
      // Expand radius and retry
      await sleep(5000);
      await findAndAssignDriver(order, merchant, EXPANDED_RADIUS_KM, correlationId, attempt + 1);
    } else {
      // Mark as expired
      await expireOrder(order.id, correlationId);
    }
    return;
  }

  // Select top N drivers
  const selectedDrivers = onlineDrivers.slice(0, DEFAULT_FANOUT_COUNT);

  // Calculate estimated earnings for each driver
  const pricing = calculatePricing(
    selectedDrivers[0].distanceKm,
    estimateEtaSec(selectedDrivers[0].distanceKm) / 60,
    merchant?.settings?.baseFare ?? 300,
    merchant?.settings?.perKmRate ?? 50,
    merchant?.settings?.perMinuteRate ?? 10,
    merchant?.settings?.minimumFare ?? 300
  );

  const driverPayoutPercent = merchant?.settings?.driverPayoutPercent ?? 0.75;
  const estimatedEarnings = pricing.total * driverPayoutPercent;

  // Create offer documents
  const offerDocs: Offer[] = selectedDrivers.map((driver) => ({
    id: `offer_${order.id}_${driver.id}_${Date.now()}`,
    orderId: order.id,
    driverId: driver.id,
    merchantId: order.merchantId,
    state: 'sent' as OfferState,
    sentAt: admin.firestore.FieldValue.serverTimestamp() as any,
    expiresAt: admin.firestore.Timestamp.fromMillis(
      Date.now() + DEFAULT_OFFER_TTL_SECONDS * 1000
    ) as any,
    estimatedEarnings: Math.round(estimatedEarnings * 100) / 100,
  }));

  // Batch write offers
  const batch = db.batch();
  offerDocs.forEach((offer) => {
    batch.set(db.collection('offers').doc(offer.id), offer);
  });
  await batch.commit();

  structuredLog('info', 'Offers created', {
    correlationId,
    orderId: order.id,
    offerCount: offerDocs.length,
    drivers: selectedDrivers.map((d) => ({ id: d.id, distanceKm: d.distanceKm })),
  });

  // Send FCM offers
  const driversWithTokens = selectedDrivers
    .filter((d) => d.fcmToken)
    .map((d, i) => ({
      token: d.fcmToken!,
      driverId: d.id,
      distanceKm: d.distanceKm,
      offerId: offerDocs[i].id,
    }));

  if (driversWithTokens.length > 0) {
    await sendOrderOffers(
      driversWithTokens,
      {
        offerId: driversWithTokens[0].offerId,
        orderId: order.id,
        merchantName: merchant?.name || 'Comercio',
        pickupAddress: order.pickup.address,
        dropoffAddress: order.dropoff.address,
        estimatedEarnings,
        distanceKm: driversWithTokens[0].distanceKm,
        expiresAt: new Date(Date.now() + DEFAULT_OFFER_TTL_SECONDS * 1000),
      }
    );
  }

  // Schedule expiry check
  setTimeout(() => checkOfferExpiry(order.id, correlationId), DEFAULT_OFFER_TTL_SECONDS * 1000 + 2000);
}

/**
 * Accept an offer and assign driver to order
 */
export async function acceptOffer(
  orderId: string,
  driverId: string
): Promise<{ success: boolean; assigned: boolean; message: string }> {
  const correlationId = `accept-${orderId}-${driverId}-${Date.now()}`;

  structuredLog('info', 'Driver attempting to accept offer', {
    correlationId,
    orderId,
    driverId,
  });

  try {
    const orderRef = db.collection('orders').doc(orderId);
    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      return { success: false, assigned: false, message: 'Orden no encontrada' };
    }

    const order = { id: orderSnap.id, ...orderSnap.data() } as Order;

    // Check if already assigned
    if (order.assignedDriverId) {
      return {
        success: false,
        assigned: false,
        message: order.assignedDriverId === driverId
          ? 'Ya aceptaste esta orden'
          : 'Orden ya asignada a otro repartidor',
      };
    }

    // Check if still in searching state
    if (order.status !== 'searching') {
      return { success: false, assigned: false, message: 'Orden no disponible' };
    }

    // Find the driver's offer
    const offersSnapshot = await db
      .collection('offers')
      .where('orderId', '==', orderId)
      .where('driverId', '==', driverId)
      .where('state', '==', 'sent')
      .limit(1)
      .get();

    if (offersSnapshot.empty) {
      return { success: false, assigned: false, message: 'Oferta no encontrada o expirada' };
    }

    const offerDoc = offersSnapshot.docs[0];
    const offer = offerDoc.data() as Offer;

    // Check if offer expired
    const expiresAt = (offer.expiresAt as any).toMillis?.() || Date.now();
    if (Date.now() > expiresAt) {
      await offerDoc.ref.update({ state: 'expired' as OfferState });
      return { success: false, assigned: false, message: 'Oferta expirada' };
    }

    // Transaction: accept offer and assign driver atomically
    const batch = db.batch();

    // Update offer to accepted
    batch.update(offerDoc.ref, {
      state: 'accepted' as OfferState,
      respondedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Expire all other offers for this order
    const otherOffersSnapshot = await db
      .collection('offers')
      .where('orderId', '==', orderId)
      .where('state', '==', 'sent')
      .get();

    otherOffersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        state: 'expired' as OfferState,
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Assign driver to order
    const etaSec = estimateEtaSec(
      order.pickup?.geo && order.dropoff?.geo
        ? haversineDistance(order.pickup.geo.lat, order.pickup.geo.lng, order.dropoff.geo.lat, order.dropoff.geo.lng)
        : 0
    );

    batch.update(orderRef, {
      status: 'assigned' as OrderStatus,
      assignedDriverId: driverId,
      etaSec,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      timeline: admin.firestore.FieldValue.arrayUnion({
        status: 'assigned',
        ts: admin.firestore.FieldValue.serverTimestamp(),
        by: driverId,
        note: 'Driver accepted offer',
      }),
    });

    // Update driver to busy
    const driverRef = db.collection('drivers').doc(driverId);
    batch.update(driverRef, {
      status: 'busy',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    structuredLog('info', 'Driver assigned to order', {
      correlationId,
      orderId,
      driverId,
    });

    // Notify merchant
    const merchantUserSnap = await db
      .collection('users')
      .where('merchantId', '==', order.merchantId)
      .limit(1)
      .get();

    const merchantTokens = merchantUserSnap.docs
      .map((d) => d.data().fcmToken as string | undefined)
      .filter(Boolean) as string[];

    const driverSnap = await db.collection('drivers').doc(driverId).get();
    const driverData = driverSnap.data();

    if (merchantTokens.length > 0) {
      await sendStatusUpdate(merchantTokens, {
        orderId: order.id,
        status: 'assigned',
        message: 'Repartidor asignado a tu orden',
        etaSec,
        driverName: driverData?.displayName || 'Repartidor',
      });
    }

    return { success: true, assigned: true, message: 'Orden asignada exitosamente' };
  } catch (err) {
    structuredLog('error', 'Failed to accept offer', {
      correlationId,
      orderId,
      driverId,
      error: (err as Error).message,
    });
    return { success: false, assigned: false, message: 'Error interno del servidor' };
  }
}

/**
 * Check if offers have expired and handle fallback
 */
async function checkOfferExpiry(orderId: string, correlationId: string): Promise<void> {
  try {
    const orderRef = db.collection('orders').doc(orderId);
    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) return;

    const order = { id: orderSnap.id, ...orderSnap.data() } as Order;

    // If already assigned, nothing to do
    if (order.assignedDriverId || order.status !== 'searching') {
      return;
    }

    // Check if any offers are still pending
    const pendingOffers = await db
      .collection('offers')
      .where('orderId', '==', orderId)
      .where('state', '==', 'sent')
      .limit(1)
      .get();

    if (!pendingOffers.empty) {
      // Still waiting, check again later
      setTimeout(() => checkOfferExpiry(orderId, correlationId), 10000);
      return;
    }

    // All offers expired without acceptance
    structuredLog('warn', 'All offers expired, no driver accepted', {
      correlationId,
      orderId,
    });

    // Expire the order
    await expireOrder(orderId, correlationId);
  } catch (err) {
    structuredLog('error', 'Error checking offer expiry', {
      correlationId,
      orderId,
      error: (err as Error).message,
    });
  }
}

/**
 * Mark order as expired
 */
async function expireOrder(orderId: string, correlationId: string): Promise<void> {
  try {
    const orderRef = db.collection('orders').doc(orderId);
    await orderRef.update({
      status: 'expired' as OrderStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      timeline: admin.firestore.FieldValue.arrayUnion({
        status: 'expired',
        ts: admin.firestore.FieldValue.serverTimestamp(),
        by: 'system',
        note: 'No drivers accepted within timeout',
      }),
    });

    structuredLog('info', 'Order expired', { correlationId, orderId });

    // Notify merchant
    const orderSnap = await orderRef.get();
    const order = orderSnap.data() as Order;

    const merchantUserSnap = await db
      .collection('users')
      .where('merchantId', '==', order.merchantId)
      .limit(1)
      .get();

    const merchantTokens = merchantUserSnap.docs
      .map((d) => d.data().fcmToken as string | undefined)
      .filter(Boolean) as string[];

    if (merchantTokens.length > 0) {
      await sendStatusUpdate(merchantTokens, {
        orderId,
        status: 'expired',
        message: 'No se encontraron repartidores disponibles. Intentá de nuevo.',
      });
    }
  } catch (err) {
    structuredLog('error', 'Failed to expire order', {
      correlationId,
      orderId,
      error: (err as Error).message,
    });
  }
}

/**
 * Handle order status transitions with validation
 */
export async function transitionOrderStatus(
  orderId: string,
  newStatus: OrderStatus,
  userId: string,
  note?: string
): Promise<{ success: boolean; message: string }> {
  const correlationId = `transition-${orderId}-${newStatus}-${Date.now()}`;

  try {
    const orderRef = db.collection('orders').doc(orderId);
    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      return { success: false, message: 'Orden no encontrada' };
    }

    const order = { id: orderSnap.id, ...orderSnap.data() } as Order;

    if (!isValidStateTransition(order.status, newStatus)) {
      return {
        success: false,
        message: `Transición inválida: ${order.status} → ${newStatus}`,
      };
    }

    const updates: Record<string, unknown> = {
      status: newStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      timeline: admin.firestore.FieldValue.arrayUnion({
        status: newStatus,
        ts: admin.firestore.FieldValue.serverTimestamp(),
        by: userId,
        note: note || '',
      }),
    };

    // Handle pickup
    if (newStatus === 'picked_up') {
      updates.pickedUpAt = admin.firestore.FieldValue.serverTimestamp();
    }

    // Handle delivery
    if (newStatus === 'delivered') {
      updates.deliveredAt = admin.firestore.FieldValue.serverTimestamp();
      // Free up driver
      if (order.assignedDriverId) {
        const driverRef = db.collection('drivers').doc(order.assignedDriverId);
        await driverRef.update({
          online: true,
          status: 'online',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    // Handle cancellation
    if (newStatus === 'canceled') {
      // Expire any pending offers
      const pendingOffers = await db
        .collection('offers')
        .where('orderId', '==', orderId)
        .where('state', '==', 'sent')
        .get();

      const batch = db.batch();
      pendingOffers.docs.forEach((doc) => {
        batch.update(doc.ref, {
          state: 'expired',
          respondedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();

      // Free driver if assigned
      if (order.assignedDriverId) {
        const driverRef = db.collection('drivers').doc(order.assignedDriverId);
        await driverRef.update({
          status: 'online',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Notify driver
        const driverUser = await db.collection('users').doc(order.assignedDriverId).get();
        const driverToken = driverUser.data()?.fcmToken as string | undefined;
        if (driverToken) {
          await sendStatusUpdate([driverToken], {
            orderId,
            status: 'canceled',
            message: 'La orden fue cancelada por el comercio',
          });
        }
      }
    }

    await orderRef.update(updates);

    structuredLog('info', 'Order status transitioned', {
      correlationId,
      orderId,
      oldStatus: order.status,
      newStatus,
      userId,
    });

    return { success: true, message: `Estado actualizado a: ${newStatus}` };
  } catch (err) {
    structuredLog('error', 'Status transition failed', {
      correlationId,
      orderId,
      newStatus,
      error: (err as Error).message,
    });
    return { success: false, message: 'Error interno del servidor' };
  }
}
