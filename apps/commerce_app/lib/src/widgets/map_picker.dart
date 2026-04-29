// Widget de selector de ubicación en mapa para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:geolocator/geolocator.dart';

/// Pantalla para seleccionar una ubicación en el mapa
/// 
/// Muestra un mapa interactivo con un pin arrastrable.
/// Emite la lat/lng seleccionada al navegar hacia atrás.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  
  // Ubicación inicial (Buenos Aires por defecto)
  static const LatLng _initialPosition = LatLng(-34.6037, -58.3816);
  LatLng _currentPosition = _initialPosition;
  
  bool _isLoading = true;
  String? _address;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Obtener ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 15),
        );
        
        _getAddressFromCoordinates(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Obtener dirección desde coordenadas
  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    // En producción, usar geocoding package o API de Google
    setState(() {
      _address = '$lat, $lng';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        backgroundColor: KatuyaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _confirmSelection,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMove: (position) {
                    setState(() {
                      _currentPosition = position.target;
                    });
                  },
                  onCameraIdle: () {
                    _getAddressFromCoordinates(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    );
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _currentPosition,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _currentPosition = newPosition;
                        });
                        _getAddressFromCoordinates(
                          newPosition.latitude,
                          newPosition.longitude,
                        );
                      },
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueViolet,
                      ),
                    ),
                  },
                ),
          
          // Overlay central con pin (opcional, para mejor UX)
          if (!_isLoading)
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: KatuyaColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: KatuyaColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: KatuyaColors.primary,
                  size: 40,
                ),
              ),
            ),
          
          // Panel inferior con información
          if (!_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: KatuyaColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: KatuyaColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ubicación seleccionada',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _address ?? 'Cargando...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Arrastra el mapa para ajustar la ubicación',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Confirmar selección y volver
  void _confirmSelection() {
    final geoLocation = GeoLocation(
      lat: _currentPosition.latitude,
      lng: _currentPosition.longitude,
      geohash: '', // Se puede calcular con shared_utils
    );
    
    Navigator.pop(context, geoLocation);
  }
}
