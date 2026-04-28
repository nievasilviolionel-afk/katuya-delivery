/**
 * Katuya Auth Module
 * by Silvio Lionel Nieva
 *
 * Firebase Custom Claims management and Express middleware.
 */

import * as admin from 'firebase-admin';
import { Request, Response, NextFunction } from 'express';
import { UserRole, SetRoleRequest, SetRoleResponse } from './models';
import { structuredLog } from './utils';

// Initialize if not already done (safe for emulator + production)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const auth = admin.auth();
const db = admin.firestore();

/**
 * Express middleware: verify Firebase ID token and attach decoded user
 */
export async function verifyAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  const correlationId = req.headers['x-correlation-id'] as string || `req-${Date.now()}`;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decoded = await auth.verifyIdToken(idToken, true);
    (req as any).user = decoded;
    (req as any).correlationId = correlationId;
    next();
  } catch (err) {
    structuredLog('warn', 'Auth verification failed', {
      correlationId,
      error: (err as Error).message,
    });
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/**
 * Middleware factory: require specific role
 */
export function requireRole(role: UserRole) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const user = (req as any).user;
    if (!user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const userRole = user.role as UserRole;
    if (userRole !== role && userRole !== 'admin') {
      res.status(403).json({ error: `Required role: ${role}` });
      return;
    }

    next();
  };
}

/**
 * Middleware: require admin role specifically
 */
export function requireAdmin(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const user = (req as any).user;
  if (!user || user.role !== 'admin') {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
}

/**
 * Set custom claims for a user (role + optional merchantId)
 * Also updates the user document in Firestore for sync
 */
export async function setUserRole(
  req: Request,
  res: Response
): Promise<void> {
  const user = (req as any).user;
  const correlationId = (req as any).correlationId;

  try {
    const body = req.body as SetRoleRequest;

    if (!body.uid || !body.role) {
      res.status(400).json({ error: 'Missing uid or role' });
      return;
    }

    const validRoles: UserRole[] = ['admin', 'merchant', 'driver'];
    if (!validRoles.includes(body.role)) {
      res.status(400).json({ error: `Invalid role. Must be one of: ${validRoles.join(', ')}` });
      return;
    }

    // Build claims object
    const claims: Record<string, unknown> = { role: body.role };
    if (body.merchantId) {
      claims.merchantId = body.merchantId;
    }

    // Set Firebase Auth custom claims
    await auth.setCustomUserClaims(body.uid, claims);

    // Sync to Firestore user document
    const userRef = db.collection('users').doc(body.uid);
    await userRef.set(
      {
        role: body.role,
        merchantId: body.merchantId || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // If driver role, ensure driver document exists
    if (body.role === 'driver') {
      const driverRef = db.collection('drivers').doc(body.uid);
      await driverRef.set(
        {
          userId: body.uid,
          online: false,
          ratings: { avg: 0, count: 0 },
          documents: {},
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    structuredLog('info', 'Role assigned successfully', {
      correlationId,
      targetUid: body.uid,
      role: body.role,
      assignedBy: user.uid,
    });

    res.json({ success: true } as SetRoleResponse);
  } catch (err) {
    structuredLog('error', 'Failed to set role', {
      correlationId,
      error: (err as Error).message,
      stack: (err as Error).stack,
    });
    res.status(500).json({ error: 'Internal server error' });
  }
}
