/**
 * Katuya Firebase Cloud Functions Entry Point
 * by Silvio Lionel Nieva
 *
 * Exports HTTPS functions and Firestore triggers.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { app } from './api';
import { startMatching, transitionOrderStatus } from './matching';
import { structuredLog } from './utils';

// Initialize Firebase Admin SDK
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// ============================================
// HTTPS Functions (Express API)
// ============================================

/**
 * Main API — mounted Express app
 * Endpoint: https://<region>-<project>.cloudfunctions.net/api
 */
export const api = functions.https.onRequest(app);

// ============================================
// Firestore Triggers
// ============================================

/**
 * onCreate: orders/{id}
 * Triggered when a new order is created → starts driver matching
 */
export const onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const orderId = context.params.orderId;
    const correlationId = `trigger-create-${orderId}-${Date.now()}`;

    structuredLog('info', 'Order created trigger fired', {
      correlationId,
      orderId,
    });

    try {
      const order = snapshot.data();

      // Only trigger matching for orders in 'created' status
      if (order.status === 'created') {
        await startMatching(orderId);
      } else {
        structuredLog('debug', 'Order not in created state, skipping matching', {
          correlationId,
          orderId,
          status: order.status,
        });
      }
    } catch (err) {
      structuredLog('error', 'Order created trigger failed', {
        correlationId,
        orderId,
        error: (err as Error).message,
      });
    }
  });

/**
 * onUpdate: orders/{id}
 * State machine guards and side effects
 */
export const onOrderUpdated = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const orderId = context.params.orderId;
    const before = change.before.data();
    const after = change.after.data();
    const correlationId = `trigger-update-${orderId}-${Date.now()}`;

    // Only process if status changed
    if (before.status === after.status) {
      return;
    }

    structuredLog('info', 'Order status changed', {
      correlationId,
      orderId,
      oldStatus: before.status,
      newStatus: after.status,
    });

    try {
      const db = admin.firestore();

      // Handle driver going offline while assigned → auto-reassign
      if (after.status === 'assigned' && after.assignedDriverId) {
        const driverRef = db.collection('drivers').doc(after.assignedDriverId);
        const driverSnap = await driverRef.get();

        if (driverSnap.exists) {
          const driver = driverSnap.data();
          if (driver?.online === false) {
            structuredLog('warn', 'Assigned driver went offline, reassigning', {
              correlationId,
              orderId,
              driverId: after.assignedDriverId,
            });

            // Reset to searching
            await change.after.ref.update({
              status: 'searching',
              assignedDriverId: null,
              etaSec: null,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              timeline: admin.firestore.FieldValue.arrayUnion({
                status: 'searching',
                ts: admin.firestore.FieldValue.serverTimestamp(),
                by: 'system',
                note: 'Driver went offline, searching for new driver',
              }),
            });

            // Restart matching
            await startMatching(orderId);
          }
        }
      }

      // Handle delivered → create payout record
      if (after.status === 'delivered' && after.assignedDriverId) {
        const payoutRef = db.collection('payouts').doc();
        const driverPayoutPercent = 0.75; // Configurable
        const amount = Math.round((after.pricing?.total || 0) * driverPayoutPercent * 100) / 100;

        await payoutRef.set({
          driverId: after.assignedDriverId,
          orderId,
          amount,
          currency: after.pricing?.currency || 'ARS',
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        structuredLog('info', 'Payout record created', {
          correlationId,
          orderId,
          payoutId: payoutRef.id,
          driverId: after.assignedDriverId,
          amount,
        });
      }

      // Handle canceled with assigned driver → notify and free driver
      if (after.status === 'canceled' && before.assignedDriverId) {
        const driverRef = db.collection('drivers').doc(before.assignedDriverId);
        await driverRef.update({
          status: 'online',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        structuredLog('info', 'Driver freed after cancellation', {
          correlationId,
          orderId,
          driverId: before.assignedDriverId,
        });
      }
    } catch (err) {
      structuredLog('error', 'Order update trigger failed', {
        correlationId,
        orderId,
        error: (err as Error).message,
      });
    }
  });

/**
 * onWrite: drivers/{id}
 * Presence handling — detect driver going offline
 */
export const onDriverWrite = functions.firestore
  .document('drivers/{driverId}')
  .onWrite(async (change, context) => {
    const driverId = context.params.driverId;
    const correlationId = `trigger-driver-${driverId}-${Date.now()}`;

    // Driver deleted
    if (!change.after.exists) {
      structuredLog('info', 'Driver document deleted', { correlationId, driverId });
      return;
    }

    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.data();

    // Detect going offline while having active order
    if (before?.online === true && after?.online === false) {
      structuredLog('warn', 'Driver went offline', {
        correlationId,
        driverId,
      });

      // Find active assigned order
      const db = admin.firestore();
      const activeOrders = await db
        .collection('orders')
        .where('assignedDriverId', '==', driverId)
        .where('status', 'in', ['assigned', 'picked_up'])
        .limit(1)
        .get();

      if (!activeOrders.empty) {
        const orderDoc = activeOrders.docs[0];
        structuredLog('warn', 'Driver went offline with active order', {
          correlationId,
          driverId,
          orderId: orderDoc.id,
        });

        // The onOrderUpdated trigger will handle reassignment on next tick
      }
    }

    // Detect coming online
    if ((!before || before.online === false) && after.online === true) {
      structuredLog('info', 'Driver came online', {
        correlationId,
        driverId,
        location: after.lastLocation,
      });
    }
  });

/**
 * onCreate: chats/{chatId}/messages/{messageId}
 * Send FCM notification for new chat messages
 */
export const onChatMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const { chatId } = context.params;
    const message = snapshot.data();
    const correlationId = `chat-${chatId}-${Date.now()}`;

    try {
      const db = admin.firestore();

      // Get chat metadata
      const chatRef = db.collection('chats').doc(chatId);
      const chatSnap = await chatRef.get();

      if (!chatSnap.exists) return;
      const chat = chatSnap.data();

      // Determine recipient
      const senderId = message.senderId;
      const recipientId =
        senderId === chat?.merchantId ? chat?.driverId : chat?.merchantId;

      if (!recipientId) return;

      // Get recipient FCM token
      const recipientSnap = await db.collection('users').doc(recipientId).get();
      const recipientData = recipientSnap.data();
      const fcmToken = recipientData?.fcmToken as string | undefined;

      if (!fcmToken) return;

      // Send notification
      const { sendChatNotification } = await import('./fcm');
      await sendChatNotification([fcmToken], {
        chatId,
        orderId: chat?.orderId || '',
        senderName: message.senderName || 'Usuario',
        content: message.content,
        sentAt: new Date(),
      });

      structuredLog('info', 'Chat notification sent', {
        correlationId,
        chatId,
        recipientId,
      });
    } catch (err) {
      structuredLog('error', 'Chat message trigger failed', {
        correlationId,
        error: (err as Error).message,
      });
    }
  });
