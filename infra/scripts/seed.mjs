#!/usr/bin/env node
/**
 * Katuya Seed Script
 * by Silvio Lionel Nieva
 * 
 * Seeds sample data: merchants, drivers, and orders in Buenos Aires.
 * Usage: node seed.mjs [--clean] [--emulator]
 */

import { initializeApp, cert } from 'firebase-admin';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

const USE_EMULATOR = process.argv.includes('--emulator');
const CLEAN = process.argv.includes('--clean');

// Initialize Firebase Admin
if (USE_EMULATOR) {
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  initializeApp({ projectId: 'katuya-dev' });
} else {
  try {
    const serviceAccount = JSON.parse(readFileSync(join(__dirname, '../../service-account.json'), 'utf8'));
    initializeApp({ credential: cert(serviceAccount) });
  } catch {
    initializeApp();
  }
}

const db = getFirestore();

// Buenos Aires locations
const LOCATIONS = [
  { name: 'Obelisco', address: 'Av. 9 de Julio y Av. Corrientes, Buenos Aires', lat: -34.6037, lng: -58.3816 },
  { name: 'Casa Rosada', address: 'Balcarce 50, Buenos Aires', lat: -34.6084, lng: -58.3703 },
  { name: 'Palermo Soho', address: 'Plaza Serrano, Buenos Aires', lat: -34.5895, lng: -58.4268 },
  { name: 'Recoleta', address: 'Av. Callao y Av. Alvear, Buenos Aires', lat: -34.5883, lng: -58.3930 },
  { name: 'Puerto Madero', address: 'Av. Juana Manso 500, Buenos Aires', lat: -34.6142, lng: -58.3625 },
  { name: 'Belgrano', address: 'Av. Cabildo 2500, Buenos Aires', lat: -34.5630, lng: -58.4560 },
  { name: 'San Telmo', address: 'Defensa 1000, Buenos Aires', lat: -34.6190, lng: -58.3720 },
  { name: 'Retiro', address: 'Av. Dr. José María Ramos Mejía 1300, Buenos Aires', lat: -34.5920, lng: -58.3750 },
  { name: 'Caballito', address: 'Av. Rivadavia 5000, Buenos Aires', lat: -34.6180, lng: -58.4360 },
  { name: 'Villa Crespo', address: 'Av. Corrientes 5500, Buenos Aires', lat: -34.5970, lng: -58.4440 },
];

function encodeGeohash(lat, lng) {
  // Simplified geohash for seeding
  return '69y7b0h6s';
}

async function clean() {
  console.log('Cleaning existing data...');
  const collections = ['merchants', 'drivers', 'orders', 'offers', 'payouts', 'chats', 'ratings'];
  for (const col of collections) {
    const snapshot = await db.collection(col).get();
    const batch = db.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    console.log(`  Deleted ${snapshot.size} documents from ${col}`);
  }
}

async function seedMerchants() {
  console.log('Seeding merchants...');
  const merchants = [
    { name: 'Panadería Buenos Aires', legalName: 'Panadería BA SRL', taxId: '30-12345678-1', radius: 5 },
    { name: 'Café del Centro', legalName: 'Café Centro S.A.', taxId: '30-23456789-2', radius: 3 },
    { name: 'Librería Cultural', legalName: 'Librería Cultural SAS', taxId: '30-34567890-3', radius: 8 },
    { name: 'Tech Store Palermo', legalName: 'Tech Store SRL', taxId: '30-45678901-4', radius: 6 },
    { name: 'Verdulería Orgánica', legalName: 'Verdulería Orgánica S.A.', taxId: '30-56789012-5', radius: 4 },
  ];

  for (let i = 0; i < merchants.length; i++) {
    const m = merchants[i];
    const loc = LOCATIONS[i % LOCATIONS.length];
    const ref = db.collection('merchants').doc(`merchant_${i + 1}`);
    await ref.set({
      id: ref.id,
      name: m.name,
      legalName: m.legalName,
      taxId: m.taxId,
      address: loc.address,
      geo: { lat: loc.lat, lng: loc.lng, geohash: encodeGeohash(loc.lat, loc.lng) },
      status: 'active',
      settings: {
        autoAssign: true,
        deliveryRadiusKm: m.radius,
        cancelTimeoutSec: 300,
        currency: 'ARS',
        baseFare: 300 + i * 50,
        perKmRate: 50,
        perMinuteRate: 10,
        minimumFare: 300,
        serviceFeePercent: 15,
        driverPayoutPercent: 75,
      },
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  console.log(`  Created ${merchants.length} merchants`);
}

async function seedDrivers() {
  console.log('Seeding drivers...');
  const vehicles = [
    { type: 'motorcycle', plate: 'ABC123' },
    { type: 'motorcycle', plate: 'DEF456' },
    { type: 'bike', plate: 'GHI789' },
    { type: 'car', plate: 'JKL012' },
    { type: 'motorcycle', plate: 'MNO345' },
    { type: 'motorcycle', plate: 'PQR678' },
    { type: 'bike', plate: 'STU901' },
    { type: 'motorcycle', plate: 'VWX234' },
    { type: 'car', plate: 'YZA567' },
    { type: 'motorcycle', plate: 'BCD890' },
  ];

  for (let i = 0; i < vehicles.length; i++) {
    const v = vehicles[i];
    const loc = LOCATIONS[(i + 5) % LOCATIONS.length];
    const isOnline = i < 6; // 60% online
    const ref = db.collection('drivers').doc(`driver_${i + 1}`);
    await ref.set({
      id: ref.id,
      userId: `user_driver_${i + 1}`,
      vehicle: v,
      online: isOnline,
      lastLocation: isOnline ? {
        lat: loc.lat + (Math.random() - 0.5) * 0.01,
        lng: loc.lng + (Math.random() - 0.5) * 0.01,
        geohash: encodeGeohash(loc.lat, loc.lng),
        ts: Timestamp.now(),
      } : null,
      ratings: { avg: 4.0 + Math.random(), count: Math.floor(Math.random() * 50) },
      documents: { dni: 'uploaded', license: 'uploaded' },
      status: isOnline ? 'online' : 'offline',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  console.log(`  Created ${vehicles.length} drivers`);
}

async function seedOrders() {
  console.log('Seeding orders...');
  const statuses = ['created', 'searching', 'assigned', 'picked_up', 'delivered', 'canceled', 'expired'];

  for (let i = 0; i < 15; i++) {
    const merchantIdx = (i % 5) + 1;
    const pickupLoc = LOCATIONS[i % LOCATIONS.length];
    const dropoffLoc = LOCATIONS[(i + 2) % LOCATIONS.length];
    const status = statuses[i % statuses.length];

    const ref = db.collection('orders').doc(`order_${i + 1}`);
    const distanceKm = Math.random() * 8 + 1;
    const timeMin = distanceKm * 2.5;

    await ref.set({
      id: ref.id,
      merchantId: `merchant_${merchantIdx}`,
      createdBy: `user_merchant_${merchantIdx}`,
      status,
      pickup: {
        name: `Local ${merchantIdx}`,
        address: pickupLoc.address,
        geo: { lat: pickupLoc.lat, lng: pickupLoc.lng, geohash: encodeGeohash(pickupLoc.lat, pickupLoc.lng) },
      },
      dropoff: {
        name: `Cliente ${i + 1}`,
        phone: `+54911${Math.floor(10000000 + Math.random() * 90000000)}`,
        address: dropoffLoc.address,
        geo: { lat: dropoffLoc.lat, lng: dropoffLoc.lng, geohash: encodeGeohash(dropoffLoc.lat, dropoffLoc.lng) },
      },
      pricing: {
        base: 300,
        distanceKm: Math.round(distanceKm * 100) / 100,
        timeMin: Math.round(timeMin * 100) / 100,
        total: Math.round((300 + distanceKm * 50 + timeMin * 10) * 100) / 100,
        currency: 'ARS',
      },
      assignedDriverId: ['assigned', 'picked_up', 'delivered'].includes(status) ? `driver_${(i % 10) + 1}` : null,
      etaSec: Math.floor(distanceKm * 3600 / 25),
      timeline: [{
        status: 'created',
        ts: Timestamp.fromMillis(Date.now() - Math.random() * 86400000),
        by: `user_merchant_${merchantIdx}`,
        note: '',
      }],
      createdAt: Timestamp.fromMillis(Date.now() - Math.random() * 86400000),
      updatedAt: Timestamp.now(),
    });
  }
  console.log(`  Created 15 orders`);
}

async function main() {
  console.log('=== Katuya Seed Script ===');
  console.log(`by Silvio Lionel Nieva\n`);

  if (CLEAN) await clean();
  await seedMerchants();
  await seedDrivers();
  await seedOrders();

  console.log('\nSeed complete!');
  process.exit(0);
}

main().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});
