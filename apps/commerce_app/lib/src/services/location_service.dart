// Servicio de ubicación para Katuya Comercio
// by Silvio Lionel Nieva

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocode;
import 'package:shared_models/shared_models.dart';
import 'shared_utils/location_utils.dart' as location_utils;

/// Servicio para gestionar operaciones de ubicación y geolocalización
class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();

  /// Stream de la posición actual del usuario
  Stream<Position> get positionStream => _positionController.stream;

  /// Obtener la posición actual
  Future<Position?> getCurrentPosition() async {
    try {
      // Verificar permisos
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('❌ Permiso de ubicación denegado');
        return null;
      }

      // Obtener posición actual
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('📍 Posición obtenida: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      return _currentPosition;
    } catch (e) {
      debugPrint('❌ Error al obtener posición: $e');
      return null;
    }
  }

  /// Solicitar permiso de ubicación
  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Verificar si el servicio de ubicación está habilitado
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Servicio de ubicación deshabilitado');
        return false;
      }

      // Verificar permisos
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Permiso de ubicación denegado');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permiso de ubicación denegado permanentemente');
        // En producción, mostrar diálogo para abrir configuración
        return false;
      }

      debugPrint('✅ Permiso de ubicación concedido');
      return true;
    } catch (e) {
      debugPrint('❌ Error al solicitar permiso: $e');
      return false;
    }
  }

  /// Iniciar seguimiento de ubicación en tiempo real
  void startTracking({Duration interval = const Duration(seconds: 5)}) {
    try {
      // Cancelar seguimiento anterior si existe
      stopTracking();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Actualizar cada 10 metros
        ),
      ).listen((Position position) {
        _currentPosition = position;
        _positionController.add(position);
        
        debugPrint('🔄 Posición actualizada: ${position.latitude}, ${position.longitude}');
      });

      debugPrint('▶️ Seguimiento de ubicación iniciado');
    } catch (e) {
      debugPrint('❌ Error al iniciar seguimiento: $e');
    }
  }

  /// Detener seguimiento de ubicación
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    debugPrint('⏹️ Seguimiento de ubicación detenido');
  }

  /// Obtener dirección desde coordenadas (geocodificación inversa)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await geocode.placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        
        debugPrint('🏠 Dirección obtenida: $address');
        return address;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error en geocodificación inversa: $e');
      return null;
    }
  }

  /// Obtener coordenadas desde una dirección (geocodificación directa)
  Future<GeoLocation?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await geocode.locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final geo = GeoLocation(
          lat: location.latitude,
          lng: location.longitude,
          geohash: location_utils.encodeGeohash(location.latitude, location.longitude),
        );
        
        debugPrint('🎯 Coordenadas obtenidas: ${geo.lat}, ${geo.lng}');
        return geo;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error en geocodificación directa: $e');
      return null;
    }
  }

  /// Calcular distancia entre dos puntos en metros
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Calcular distancia entre dos puntos en kilómetros
  double calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    return calculateDistance(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Crear un objeto Address desde una posición
  Future<Address?> createAddressFromPosition(Position position) async {
    final street = await getAddressFromCoordinates(position.latitude, position.longitude);
    
    if (street == null) return null;
    
    return Address(
      street: street,
      city: '',
      state: '',
      country: 'Argentina',
      postalCode: '',
    );
  }

  /// Crear un objeto Location desde una posición
  Location createLocationFromPosition(Position position) {
    return Location(
      lat: position.latitude,
      lng: position.longitude,
      geohash: location_utils.encodeGeohash(position.latitude, position.longitude),
      ts: DateTime.now(),
    );
  }

  /// Obtener la última posición conocida
  Position? getLastKnownPosition() {
    return _currentPosition;
  }

  /// Limpiar recursos
  void dispose() {
    stopTracking();
    _positionController.close();
  }
}

/// Singleton para el servicio de ubicación
final locationService = LocationService();
