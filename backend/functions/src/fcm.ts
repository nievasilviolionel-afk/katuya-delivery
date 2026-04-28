/**
 * Katuya FCM (Firebase Cloud Messaging) Module
 * by Silvio Lionel Nieva
 *
 * Typed FCM senders for offers, status updates, and chat.
 */

import * as admin from 'firebase-admin';
import { structuredLog } from './utils';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const messaging = admin.messaging();

export interface FCMOrderOfferPayload {
  type: 'order_offer';
  offerId: string;
  orderId: string;
  merchantName: string;
  pickupAddress: string;
  dropoffAddress: string;
  estimatedEarnings: string;
  distanceKm: string;
  expiresAt: string; // ISO timestamp
}

export interface FCMOrderStatusPayload {
  type: 'order_status';
  orderId: string;
  status: string;
  message: string;
  etaSec?: string;
  driverName?: string;
}

export interface FCMChatPayload {
  type: 'chat_message';
  chatId: string;
  orderId: string;
  senderName: string;
  content: string;
  sentAt: string;
}

export type FCMDataPayload = FCMOrderOfferPayload | FCMOrderStatusPayload | FCMChatPayload;

/**
 * Send FCM data message to a single device token
 */
export async function sendToDevice(
  token: string,
  payload: FCMDataPayload,
  priority: 'high' | 'normal' = 'high'
): Promise<admin.messaging.MessagingDevicesResponse> {
  const message: admin.messaging.Message = {
    token,
    data: payload as unknown as Record<string, string>,
    android: {
      priority,
      notification: {
        channelId: 'katuya_orders',
        priority: 'high',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    structuredLog('info', 'FCM sent to device', {
      token: token.substring(0, 20) + '...',
      type: payload.type,
      messageId: response,
    });
    return { results: [{ messageId: response }], canonicalRegistrationTokenCount: 0, failureCount: 0, successCount: 1, multicastId: 0 } as any;
  } catch (err) {
    structuredLog('error', 'FCM send failed', {
      token: token.substring(0, 20) + '...',
      type: payload.type,
      error: (err as Error).message,
    });
    throw err;
  }
}

/**
 * Send FCM data message to multiple device tokens (multicast)
 */
export async function sendToDevices(
  tokens: string[],
  payload: FCMDataPayload,
  priority: 'high' | 'normal' = 'high'
): Promise<admin.messaging.BatchResponse> {
  if (tokens.length === 0) {
    return { responses: [], successCount: 0, failureCount: 0 };
  }

  const messages: admin.messaging.Message[] = tokens.map((token) => ({
    token,
    data: payload as unknown as Record<string, string>,
    android: {
      priority,
      notification: {
        channelId: 'katuya_orders',
        priority: 'high',
      },
    },
  }));

  try {
    const response = await messaging.sendEach(messages);
    structuredLog('info', 'FCM multicast complete', {
      type: payload.type,
      targetCount: tokens.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    // Clean up invalid tokens
    const invalidTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const error = resp.error;
        if (
          error?.code === 'messaging/invalid-registration-token' ||
          error?.code === 'messaging/registration-token-not-registered'
        ) {
          invalidTokens.push(tokens[idx]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      structuredLog('warn', 'Removing invalid FCM tokens', {
        count: invalidTokens.length,
      });
      await removeInvalidTokens(invalidTokens);
    }

    return response;
  } catch (err) {
    structuredLog('error', 'FCM multicast failed', {
      type: payload.type,
      error: (err as Error).message,
    });
    throw err;
  }
}

/**
 * Send order offer to a batch of drivers
 */
export async function sendOrderOffers(
  driverTokens: { token: string; driverId: string }[],
  offer: {
    offerId: string;
    orderId: string;
    merchantName: string;
    pickupAddress: string;
    dropoffAddress: string;
    estimatedEarnings: number;
    distanceKm: number;
    expiresAt: Date;
  }
): Promise<void> {
  const payload: FCMOrderOfferPayload = {
    type: 'order_offer',
    offerId: offer.offerId,
    orderId: offer.orderId,
    merchantName: offer.merchantName,
    pickupAddress: offer.pickupAddress,
    dropoffAddress: offer.dropoffAddress,
    estimatedEarnings: offer.estimatedEarnings.toFixed(2),
    distanceKm: offer.distanceKm.toFixed(2),
    expiresAt: offer.expiresAt.toISOString(),
  };

  const tokens = driverTokens.map((d) => d.token);
  await sendToDevices(tokens, payload, 'high');
}

/**
 * Send status update to merchant and/or driver
 */
export async function sendStatusUpdate(
  tokens: string[],
  update: {
    orderId: string;
    status: string;
    message: string;
    etaSec?: number;
    driverName?: string;
  }
): Promise<void> {
  const payload: FCMOrderStatusPayload = {
    type: 'order_status',
    orderId: update.orderId,
    status: update.status,
    message: update.message,
    etaSec: update.etaSec?.toString(),
    driverName: update.driverName,
  };

  await sendToDevices(tokens, payload, 'normal');
}

/**
 * Send chat message notification
 */
export async function sendChatNotification(
  tokens: string[],
  chat: {
    chatId: string;
    orderId: string;
    senderName: string;
    content: string;
    sentAt: Date;
  }
): Promise<void> {
  const payload: FCMChatPayload = {
    type: 'chat_message',
    chatId: chat.chatId,
    orderId: chat.orderId,
    senderName: chat.senderName,
    content: chat.content,
    sentAt: chat.sentAt.toISOString(),
  };

  await sendToDevices(tokens, payload, 'high');
}

/**
 * Remove invalid FCM tokens from user documents
 */
async function removeInvalidTokens(invalidTokens: string[]): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  for (const token of invalidTokens) {
    // Find user with this token and remove it
    const usersSnapshot = await db
      .collection('users')
      .where('fcmToken', '==', token)
      .limit(1)
      .get();

    usersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        fcmToken: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }

  await batch.commit();
}
