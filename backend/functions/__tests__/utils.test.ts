/**
 * Katuya Backend Tests — Matching Algorithm
 * by Silvio Lionel Nieva
 */

import {
  isValidStateTransition,
  isTimelineEventDuplicate,
  haversineDistance,
  encodeGeohash,
  estimateEtaSec,
  calculatePricing,
} from '../src/utils';

describe('Utils', () => {
  describe('isValidStateTransition', () => {
    it('allows created -> searching', () => {
      expect(isValidStateTransition('created', 'searching')).toBe(true);
    });

    it('allows created -> canceled', () => {
      expect(isValidStateTransition('created', 'canceled')).toBe(true);
    });

    it('allows searching -> assigned', () => {
      expect(isValidStateTransition('searching', 'assigned')).toBe(true);
    });

    it('allows assigned -> picked_up', () => {
      expect(isValidStateTransition('assigned', 'picked_up')).toBe(true);
    });

    it('allows picked_up -> delivered', () => {
      expect(isValidStateTransition('picked_up', 'delivered')).toBe(true);
    });

    it('denies delivered -> assigned', () => {
      expect(isValidStateTransition('delivered', 'assigned')).toBe(false);
    });

    it('denies created -> delivered', () => {
      expect(isValidStateTransition('created', 'delivered')).toBe(false);
    });

    it('denies unknown -> anything', () => {
      expect(isValidStateTransition('unknown', 'searching')).toBe(false);
    });
  });

  describe('isTimelineEventDuplicate', () => {
    it('returns false for empty timeline', () => {
      expect(isTimelineEventDuplicate([], 'created', 'user1')).toBe(false);
    });

    it('detects duplicate within 5 seconds', () => {
      const now = Date.now();
      const timeline = [
        {
          status: 'created',
          by: 'user1',
          ts: {
            toMillis: () => now - 2000,
          } as any,
        },
      ];
      expect(isTimelineEventDuplicate(timeline, 'created', 'user1')).toBe(true);
    });

    it('allows non-duplicate events', () => {
      const now = Date.now();
      const timeline = [
        {
          status: 'searching',
          by: 'user1',
          ts: {
            toMillis: () => now - 2000,
          } as any,
        },
      ];
      expect(isTimelineEventDuplicate(timeline, 'created', 'user1')).toBe(false);
    });
  });

  describe('haversineDistance', () => {
    it('calculates distance between Buenos Aires landmarks', () => {
      // Obelisco to Casa Rosada (~1.4km)
      const dist = haversineDistance(-34.6037, -58.3816, -34.6084, -58.3703);
      expect(dist).toBeGreaterThan(1.0);
      expect(dist).toBeLessThan(2.0);
    });

    it('returns 0 for same point', () => {
      expect(haversineDistance(-34.6037, -58.3816, -34.6037, -58.3816)).toBe(0);
    });
  });

  describe('encodeGeohash', () => {
    it('encodes Buenos Aires coordinates', () => {
      const hash = encodeGeohash(-34.6037, -58.3816);
      expect(hash).toBeTruthy();
      expect(hash.length).toBeGreaterThanOrEqual(9);
    });
  });

  describe('estimateEtaSec', () => {
    it('estimates reasonable ETA for short distances', () => {
      const eta = estimateEtaSec(2); // 2km
      expect(eta).toBeGreaterThan(200); // ~5 min
      expect(eta).toBeLessThan(400);
    });

    it('estimates reasonable ETA for longer distances', () => {
      const eta = estimateEtaSec(10); // 10km
      expect(eta).toBeGreaterThan(1200); // ~24 min
      expect(eta).toBeLessThan(1800);
    });
  });

  describe('calculatePricing', () => {
    it('calculates basic pricing correctly', () => {
      const result = calculatePricing(5, 15, 300, 50, 10, 300);
      expect(result.base).toBe(300);
      expect(result.total).toBeGreaterThanOrEqual(300);
    });

    it('applies surge multiplier', () => {
      const normal = calculatePricing(5, 15, 300, 50, 10, 300, 1.0);
      const surge = calculatePricing(5, 15, 300, 50, 10, 300, 1.5);
      expect(surge.total).toBeGreaterThan(normal.total);
    });

    it('respects minimum fare', () => {
      const result = calculatePricing(0.5, 2, 300, 50, 10, 300);
      expect(result.total).toBeGreaterThanOrEqual(300);
    });
  });
});
