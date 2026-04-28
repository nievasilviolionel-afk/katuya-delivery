/**
 * Katuya Backend Utilities
 * by Silvio Lionel Nieva
 */

import * as admin from 'firebase-admin';
import { getGeohashForLocation, getGeohashRange } from 'geofire-common';

const EARTH_RADIUS_KM = 6371;

/**
 * Encode lat/lng to geohash string
 */
export function encodeGeohash(lat: number, lng: number): string {
  return getGeohashForLocation([lat, lng]);
}

/**
 * Get geohash ranges for a given radius (for Firestore compound queries)
 */
export function getGeohashRangesForRadius(
  lat: number,
  lng: number,
  radiusKm: number
): { start: string; end: string }[] {
  return getGeohashRange([lat, lng], radiusKm * 1000);
}

/**
 * Haversine distance between two points in kilometers
 */
export function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

/**
 * Generate a correlation ID for request tracing
 */
export function generateCorrelationId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 11)}`;
}

/**
 * Structured logger with correlation ID support
 */
export function structuredLog(
  level: 'debug' | 'info' | 'warn' | 'error',
  message: string,
  context: {
    correlationId?: string;
    orderId?: string;
    merchantId?: string;
    driverId?: string;
    userId?: string;
    [key: string]: unknown;
  } = {}
): void {
  const logEntry = {
    level,
    message,
    timestamp: new Date().toISOString(),
    service: 'katuya-functions',
    ...context,
  };

  // Use console methods appropriate to level for Firebase Functions logging
  switch (level) {
    case 'debug':
      console.debug(JSON.stringify(logEntry));
      break;
    case 'info':
      console.log(JSON.stringify(logEntry));
      break;
    case 'warn':
      console.warn(JSON.stringify(logEntry));
      break;
    case 'error':
      console.error(JSON.stringify(logEntry));
      break;
  }
}

/**
 * Check if an order state transition is valid
 */
export function isValidStateTransition(
  current: string,
  next: string
): boolean {
  const transitions: Record<string, string[]> = {
    created: ['searching', 'canceled'],
    searching: ['assigned', 'canceled', 'expired'],
    assigned: ['picked_up', 'canceled'],
    picked_up: ['delivered', 'canceled'],
    delivered: [],
    canceled: [],
    expired: [],
  };
  return transitions[current]?.includes(next) ?? false;
}

/**
 * Idempotency check: verify an event hasn't already been recorded in timeline
 */
export function isTimelineEventDuplicate(
  timeline: Array<{ status: string; by: string; ts?: admin.firestore.Timestamp }>,
  status: string,
  by: string
): boolean {
  if (!timeline || timeline.length === 0) return false;
  // Check last few events for duplicates within last 5 seconds
  const now = Date.now();
  return timeline.slice(-3).some(
    (event) =>
      event.status === status &&
      event.by === by &&
      event.ts &&
      Math.abs(now - event.ts.toMillis()) < 5000
  );
}

/**
 * Calculate estimated time of arrival in seconds
 * Simple heuristic: avg speed 25km/h in city
 */
export function estimateEtaSec(distanceKm: number): number {
  const avgSpeedKmh = 25;
  return Math.round((distanceKm / avgSpeedKmh) * 3600);
}

/**
 * Calculate pricing based on distance and time
 */
export function calculatePricing(
  distanceKm: number,
  timeMin: number,
  baseFare: number,
  perKmRate: number,
  perMinuteRate: number,
  minimumFare: number,
  surgeMultiplier = 1.0
): { base: number; distance: number; time: number; total: number } {
  const distanceCost = distanceKm * perKmRate;
  const timeCost = timeMin * perMinuteRate;
  const subtotal = baseFare + distanceCost + timeCost;
  const total = Math.max(minimumFare, subtotal * surgeMultiplier);

  return {
    base: baseFare,
    distance: distanceCost,
    time: timeCost,
    total: Math.round(total * 100) / 100,
  };
}

/**
 * Sanitize phone number to Argentina format
 */
export function sanitizePhone(phone: string): string {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('54')) return `+${cleaned}`;
  if (cleaned.startsWith('9')) return `+54${cleaned}`;
  return `+54${cleaned}`;
}

/**
 * Sleep utility for controlled delays
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Batch processor for Firestore writes
 */
export async function batchWrite<T>(
  db: admin.firestore.Firestore,
  items: T[],
  writeFn: (batch: admin.firestore.WriteBatch, item: T, index: number) => void,
  batchSize = 500
): Promise<void> {
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = db.batch();
    const chunk = items.slice(i, i + batchSize);
    chunk.forEach((item, idx) => writeFn(batch, item, i + idx));
    await batch.commit();
  }
}
