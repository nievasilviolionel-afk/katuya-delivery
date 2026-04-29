// Servicio de pedidos para Katuya Comercio
// by Silvio Lionel Nieva

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_models/shared_models.dart';
import 'package:http/http.dart' as http;

/// Servicio para gestionar operaciones de pedidos
class OrderService {
  final FirebaseFirestore _firestore;
  final String? _merchantId;

  OrderService(this._firestore, this._merchantId);

  /// Crear un nuevo pedido
  /// 
  /// Llama a la Cloud Function `createOrder` o crea el documento directamente
  Future<Order> createOrder({
    required Address pickupAddress,
    required GeoLocation pickupGeo,
    required Address dropoffAddress,
    required GeoLocation dropoffGeo,
    required String dropoffName,
    String? dropoffPhone,
    String? notes,
  }) async {
    if (_merchantId == null) {
      throw Exception('No hay merchantId configurado');
    }

    try {
      // Obtener información del merchant para el pricing
      final merchantDoc = await _firestore
          .collection('merchants')
          .doc(_merchantId)
          .get();

      if (!merchantDoc.exists) {
        throw Exception('Merchant no encontrado');
      }

      final merchant = Merchant.fromJson(merchantDoc.data()!);

      // Calcular distancia entre pickup y dropoff
      final distanceKm = _calculateDistance(
        pickupGeo.lat,
        pickupGeo.lng,
        dropoffGeo.lat,
        dropoffGeo.lng,
      );

      // Estimar tiempo en minutos (aproximadamente 30 km/h promedio urbano)
      final timeMin = (distanceKm / 30 * 60).ceil();

      // Calcular precio base (esto debería venir de una Cloud Function)
      final basePrice = 500.0; // Precio base en ARS
      final pricePerKm = 150.0; // Precio por km
      final pricePerMin = 50.0; // Precio por minuto

      final total = basePrice + (distanceKm * pricePerKm) + (timeMin * pricePerMin);

      // Crear objeto Pricing
      final pricing = Pricing(
        base: basePrice,
        distanceKm: distanceKm,
        timeMin: timeMin,
        total: total,
        currency: 'ARS',
      );

      // Crear el pedido
      final order = Order(
        id: '', // Se generará al guardar
        merchantId: _merchantId!,
        createdBy: _merchantId!, // El merchant crea el pedido
        status: 'created',
        pickup: LocationData(
          address: pickupAddress,
          geo: pickupGeo,
        ),
        dropoff: DropoffData(
          address: dropoffAddress,
          geo: dropoffGeo,
          name: dropoffName,
          phone: dropoffPhone,
          notes: notes,
        ),
        pricing: pricing,
        assignedDriverId: null,
        etaSec: null,
        timeline: [
          TimelineEvent(
            status: 'created',
            ts: FieldValue.serverTimestamp(),
            by: _merchantId!,
          ),
        ],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      );

      // Guardar en Firestore
      final docRef = await _firestore.collection('orders').add(order.toJson());
      
      // Actualizar el ID del pedido
      final createdOrder = order.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      debugPrint('✅ Pedido creado: ${docRef.id}');
      
      return createdOrder;
    } on FirebaseException catch (e) {
      debugPrint('❌ Error al crear pedido: $e');
      throw Exception('Error al crear pedido: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Actualizar estado del pedido
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'ts': FieldValue.serverTimestamp(),
            'by': _merchantId,
          },
        ]),
      });
      
      debugPrint('✅ Estado actualizado: $orderId -> $newStatus');
    } catch (e) {
      debugPrint('❌ Error al actualizar estado: $e');
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Cancelar pedido
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await updateOrderStatus(orderId, 'cancelled');
      
      // Añadir razón de cancelación
      await _firestore.collection('orders').doc(orderId).update({
        'cancelReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Pedido cancelado: $orderId');
    } catch (e) {
      debugPrint('❌ Error al cancelar pedido: $e');
      rethrow;
    }
  }

  /// Obtener un pedido por ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return Order.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      debugPrint('❌ Error al obtener pedido: $e');
      return null;
    }
  }

  /// Escuchar cambios en un pedido específico
  Stream<Order?> listenToOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Order.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  /// Calcular distancia entre dos puntos (fórmula Haversine)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = (dLat / 2).sin() * (dLat / 2).sin() +
              _toRadians(lat1).cos() * _toRadians(lat2).cos() *
              (dLng / 2).sin() * (dLng / 2).sin();
    
    final c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  /// Simular llamada a API REST (para compatibilidad con funciones HTTP)
  Future<Map<String, dynamic>> callApiEndpoint(String endpoint, Map<String, dynamic> data) async {
    // Esto es un placeholder para cuando se use una API REST real
    // Por ahora usamos Firestore directamente
    debugPrint('📡 Llamada API simulada: $endpoint');
    return {'success': true};
  }
}

/// Factory para crear el servicio de pedidos
OrderService createOrderService(FirebaseFirestore firestore, String? merchantId) {
  return OrderService(firestore, merchantId);
}
