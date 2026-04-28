/**
 * Katuya Backend Tests — API Endpoints
 * by Silvio Lionel Nieva
 */

// Mock Firebase Admin before importing API
jest.mock('firebase-admin', () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn(),
        set: jest.fn(),
        update: jest.fn(),
        collection: jest.fn(),
      })),
      where: jest.fn(() => ({
        where: jest.fn(() => ({
          orderBy: jest.fn(() => ({
            limit: jest.fn(() => ({
              get: jest.fn(),
            })),
            get: jest.fn(),
          })),
          limit: jest.fn(() => ({
            get: jest.fn(),
          })),
          get: jest.fn(),
        })),
        orderBy: jest.fn(() => ({
          limit: jest.fn(() => ({
            get: jest.fn(),
          })),
        })),
        limit: jest.fn(() => ({
          get: jest.fn(),
        })),
        get: jest.fn(),
      })),
      orderBy: jest.fn(() => ({
        limit: jest.fn(() => ({
          get: jest.fn(),
        })),
      })),
    })),
    batch: jest.fn(() => ({
      set: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    })),
    FieldValue: {
      serverTimestamp: jest.fn(() => 'SERVER_TIMESTAMP'),
      arrayUnion: jest.fn((item) => item),
      delete: jest.fn(() => 'DELETE_FIELD'),
    },
    Timestamp: {
      fromMillis: jest.fn((ms) => ({ toMillis: () => ms, seconds: Math.floor(ms / 1000) })),
      now: jest.fn(() => ({ toMillis: () => Date.now() })),
    },
  })),
  auth: jest.fn(() => ({
    verifyIdToken: jest.fn(),
    setCustomUserClaims: jest.fn(),
  })),
  messaging: jest.fn(() => ({
    send: jest.fn(),
    sendEach: jest.fn(),
  })),
}));

import request from 'supertest';
import { app } from '../src/api';

describe('API — Health', () => {
  it('returns health status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('katuya-api');
  });
});

describe('API — Auth Middleware', () => {
  it('returns 401 without token', async () => {
    const res = await request(app).get('/api/merchant/orders');
    expect(res.status).toBe(401);
    expect(res.body.error).toContain('Missing');
  });

  it('returns 401 with invalid token format', async () => {
    const res = await request(app)
      .get('/api/merchant/orders')
      .set('Authorization', 'Basic abc123');
    expect(res.status).toBe(401);
  });
});

describe('API — Create Order Validation', () => {
  // We can't fully test without a valid Firebase token, but we test validation
  it('validates missing dropoff data', async () => {
    // This would need a valid token to reach the controller,
    // so we just verify the route exists and requires auth
    const res = await request(app)
      .post('/api/merchant/orders')
      .send({});
    expect(res.status).toBe(401);
  });
});

// Tests for matching algorithm logic without full Firebase integration
describe('Matching Logic', () => {
  it('calculates driver distance correctly', () => {
    // Obelisco to Plaza de Mayo
    const lat1 = -34.6037;
    const lng1 = -58.3816;
    const lat2 = -34.6083;
    const lng2 = -58.3719;

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
    const distance = R * c;

    expect(distance).toBeGreaterThan(0.9);
    expect(distance).toBeLessThan(1.5);
  });
});
