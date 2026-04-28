/**
 * Katuya Backend Models
 * by Silvio Lionel Nieva
 * 
 * TypeScript interfaces mirroring the Firestore data model.
 */

import * as admin from 'firebase-admin';

export type UserRole = 'admin' | 'merchant' | 'driver';
export type DriverStatus = 'offline' | 'online' | 'busy' | 'suspended';
export type OrderStatus = 'created' | 'searching' | 'assigned' | 'picked_up' | 'delivered' | 'canceled' | 'expired';
export type VehicleType = 'bike' | 'motorcycle' | 'car';
export type OfferState = 'sent' | 'accepted' | 'declined' | 'expired';
export type MerchantStatus = 'active' | 'paused';

export interface GeoPoint {
  lat: number;
  lng: number;
  geohash: string;
}

export interface TimestampField {
  seconds: number;
  nanoseconds: number;
}

export interface UserProfile {
  uid: string;
  role: UserRole;
  merchantId?: string;
  driverStatus?: DriverStatus;
  phone: string;
  email: string;
  displayName: string;
  photoUrl?: string;
  createdAt: admin.firestore.Timestamp | TimestampField;
  updatedAt: admin.firestore.Timestamp | TimestampField;
}

export interface MerchantSettings {
  autoAssign: boolean;
  deliveryRadiusKm: number;
  cancelTimeoutSec: number;
  currency: string;
  baseFare: number;
  perKmRate: number;
  perMinuteRate: number;
  minimumFare: number;
  serviceFeePercent: number;
  driverPayoutPercent: number;
}

export interface Merchant {
  id: string;
  name: string;
  legalName: string;
  taxId?: string;
  address: string;
  geo: GeoPoint;
  status: MerchantStatus;
  settings: MerchantSettings;
  createdAt: admin.firestore.Timestamp | TimestampField;
  updatedAt: admin.firestore.Timestamp | TimestampField;
}

export interface Vehicle {
  type: VehicleType;
  plate: string;
  color?: string;
  model?: string;
}

export interface DriverRatings {
  avg: number;
  count: number;
}

export interface DriverDocuments {
  dni?: string;
  license?: string;
  insurance?: string;
  vehicleRegistration?: string;
}

export interface Driver {
  id: string;
  userId: string;
  vehicle: Vehicle;
  online: boolean;
  lastLocation?: GeoPoint & { ts: admin.firestore.Timestamp | TimestampField };
  ratings: DriverRatings;
  documents: DriverDocuments;
  createdAt: admin.firestore.Timestamp | TimestampField;
  updatedAt: admin.firestore.Timestamp | TimestampField;
}

export interface LocationDetail {
  name?: string;
  phone?: string;
  address: string;
  geo: GeoPoint;
  notes?: string;
}

export interface Pricing {
  base: number;
  distanceKm: number;
  timeMin: number;
  total: number;
  currency: string;
  surgeMultiplier?: number;
}

export interface TimelineEvent {
  status: OrderStatus;
  ts: admin.firestore.Timestamp | TimestampField;
  by: string; // userId or 'system'
  note?: string;
}

export interface Order {
  id: string;
  merchantId: string;
  createdBy: string;
  status: OrderStatus;
  pickup: LocationDetail;
  dropoff: LocationDetail;
  pricing: Pricing;
  assignedDriverId?: string;
  etaSec?: number;
  timeline: TimelineEvent[];
  chatId?: string;
  createdAt: admin.firestore.Timestamp | TimestampField;
  updatedAt: admin.firestore.Timestamp | TimestampField;
}

export interface Offer {
  id: string;
  orderId: string;
  driverId: string;
  merchantId: string;
  state: OfferState;
  sentAt: admin.firestore.Timestamp | TimestampField;
  expiresAt: admin.firestore.Timestamp | TimestampField;
  respondedAt?: admin.firestore.Timestamp | TimestampField;
  estimatedEarnings?: number;
}

export interface ChatMessage {
  id: string;
  chatId: string;
  senderId: string;
  senderRole: UserRole;
  content: string;
  sentAt: admin.firestore.Timestamp | TimestampField;
  read: boolean;
}

export interface Rating {
  id: string;
  orderId: string;
  fromRole: UserRole;
  fromId: string;
  toId: string;
  toRole: UserRole;
  score: number;
  comment?: string;
  createdAt: admin.firestore.Timestamp | TimestampField;
}

export interface Payout {
  id: string;
  driverId: string;
  orderId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'processed' | 'failed';
  processedAt?: admin.firestore.Timestamp | TimestampField;
  createdAt: admin.firestore.Timestamp | TimestampField;
}

export interface Notification {
  id: string;
  userId: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  read: boolean;
  createdAt: admin.firestore.Timestamp | TimestampField;
}

// API Request/Response types
export interface CreateOrderRequest {
  pickup?: Partial<LocationDetail>;
  dropoff: LocationDetail;
  notes?: string;
}

export interface CreateOrderResponse {
  orderId: string;
  status: OrderStatus;
  message: string;
}

export interface AcceptOfferRequest {
  orderId: string;
}

export interface AcceptOfferResponse {
  success: boolean;
  assigned: boolean;
  message: string;
}

export interface UpdateLocationRequest {
  lat: number;
  lng: number;
}

export interface UpdateLocationResponse {
  geohash: string;
  updated: boolean;
}

export interface SetRoleRequest {
  uid: string;
  role: UserRole;
  merchantId?: string;
}

export interface SetRoleResponse {
  success: boolean;
}

export interface ListOrdersRequest {
  status?: OrderStatus;
  limit?: number;
  offset?: number;
}
