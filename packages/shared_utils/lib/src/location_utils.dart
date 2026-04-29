/**
 * Utilidades de ubicación para Katuya
 * by Silvio Lionel Nieva
 * 
 * Funciones para geocodificación, cálculo de distancias,
 * permisos de ubicación y obtención de posición actual.
 */

import 'dart:math' show cos, sqrt, asin;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Codifica una coordenada (lat, lng) a geohash simple.
/// 
/// Implementa un algoritmo básico de geohash intercalando bits
/// de latitud y longitud. Para producción, considerar usar un paquete
/// especializado como `geohash`.
String encodeGeohash(double latitude, double longitude, {int precision = 6}) {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  
  // Rangos iniciales
  double latMin = -90.0;
  double latMax = 90.0;
  double lonMin = -180.0;
  double lonMax = 180.0;
  
  bool isLon = true;
  int bit = 0;
  int ch = 0;
  StringBuffer geohash = StringBuffer();
  
  while (geohash.length < precision) {
    if (isLon) {
      final mid = (lonMin + lonMax) / 2;
      if (longitude > mid) {
        ch |= (1 << (4 - bit));
        lonMin = mid;
      } else {
        lonMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (latitude > mid) {
        ch |= (1 << (4 - bit));
        latMin = mid;
      } else {
        latMax = mid;
      }
    }
    
    isLon = !isLon;
    
    if (bit < 4) {
      bit++;
    } else {
      geohash.write(base32[ch]);
      bit = 0;
      ch = 0;
    }
  }
  
  return geohash.toString();
}

/// Calcula la distancia entre dos puntos geográficos en metros.
/// 
/// Usa la fórmula Haversine para calcular la distancia del gran círculo
/// entre dos puntos en una esfera (la Tierra).
/// 
/// Parámetros:
/// - [lat1], [lng1]: Coordenadas del primer punto
/// - [lat2], [lng2]: Coordenadas del segundo punto
/// 
/// Retorna la distancia en metros.
double calculateDistance(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const double earthRadius = 6371000; // Radio de la Tierra en metros
  
  // Convertir a radianes
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  
  final lat1Rad = _toRadians(lat1);
  final lat2Rad = _toRadians(lat2);
  
  // Fórmula Haversine
  final a = sinHalfSquared(dLat) +
      cos(lat1Rad) * cos(lat2Rad) * sinHalfSquared(dLng);
  
  final c = 2 * asin(sqrt(a));
  
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * (pi / 180.0);
double sinHalfSquared(double radians) {
  final sin = sin(radians / 2);
  return sin * sin;
}

/// Solicita permiso de ubicación al usuario.
/// 
/// Retorna true si el permiso fue concedido, false en caso contrario.
/// Maneja tanto permisos "when in use" como "always" según la plataforma.
Future<bool> requestLocationPermission() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        print('Permiso de ubicación denegado por el usuario');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('Permiso de ubicación denegado permanentemente');
      // En producción, mostrar diálogo para abrir configuración
      return false;
    }
    
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  } catch (e) {
    print('Error al solicitar permiso de ubicación: $e');
    return false;
  }
}

/// Obtiene la posición actual del dispositivo.
/// 
/// Retorna un Future con la posición actual o null si hay error.
/// Requiere que el permiso de ubicación haya sido concedido previamente.
/// 
/// Parámetros opcionales:
/// - [desiredAccuracy]: Nivel de precisión deseado (por defecto: alto)
/// - [timeout]: Tiempo máximo de espera en segundos (por defecto: 30)
Future<Position?> getCurrentPosition({
  LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  int timeout = 30,
}) async {
  try {
    // Verificar si el servicio de ubicación está habilitado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicio de ubicación deshabilitado');
      return null;
    }
    
    // Verificar permisos
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final granted = await requestLocationPermission();
      if (!granted) {
        return null;
      }
    }
    
    // Obtener posición con timeout
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: desiredAccuracy,
      timeLimit: Duration(seconds: timeout),
    ).timeout(
      Duration(seconds: timeout),
      onTimeout: () {
        print('Timeout al obtener ubicación');
        return null;
      },
    );
  } catch (e) {
    print('Error al obtener posición actual: $e');
    return null;
  }
}

/// Obtiene la dirección a partir de coordenadas (geocodificación inversa).
/// 
/// Retorna una lista de direcciones posibles o lista vacía si hay error.
Future<List<String>> getAddressFromCoordinates(
  double latitude,
  double longitude,
) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    
    if (placemarks.isEmpty) {
      return [];
    }
    
    final addresses = placemarks.map((placemark) {
      final parts = <String>[];
      if (placemark.street != null && placemark.street!.isNotEmpty) {
        parts.add(placemark.street!);
      }
      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
        parts.add(placemark.subLocality!);
      }
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        parts.add(placemark.locality!);
      }
      if (placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty) {
        parts.add(placemark.administrativeArea!);
      }
      if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
        parts.add(placemark.postalCode!);
      }
      if (placemark.country != null && placemark.country!.isNotEmpty) {
        parts.add(placemark.country!);
      }
      return parts.join(', ');
    }).toList();
    
    return addresses;
  } catch (e) {
    print('Error en geocodificación inversa: $e');
    return [];
  }
}

/// Obtiene coordenadas a partir de una dirección (geocodificación directa).
/// 
/// Retorna las coordenadas del primer resultado o null si no se encuentra.
Future<Location?> getCoordinatesFromAddress(String address) async {
  try {
    final locations = await locationFromAddress(address);
    
    if (locations.isEmpty) {
      print('No se encontró la dirección: $address');
      return null;
    }
    
    final location = locations.first;
    return Location(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  } catch (e) {
    print('Error en geocodificación directa: $e');
    return null;
  }
}

/// Clase simple para representar una ubicación
class Location {
  const Location({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
  
  /// Convierte a GeoPoint de shared_models
  Map<String, dynamic> toMap({String? geohash}) {
    return {
      'lat': latitude,
      'lng': longitude,
      'geohash': geohash ?? encodeGeohash(latitude, longitude),
    };
  }
}

/// Extensión para calcular distancia desde una posición
extension PositionExtension on Position {
  /// Calcula la distancia a otra posición en metros
  double distanceTo(Position other) {
    return calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }
  
  /// Convierte a Location
  Location toLocation() {
    return Location(latitude: latitude, longitude: longitude);
  }
}
