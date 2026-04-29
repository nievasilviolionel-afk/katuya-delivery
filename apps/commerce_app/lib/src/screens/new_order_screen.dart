// Pantalla de Nuevo Pedido para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../services/location_service.dart';
import '../widgets/map_picker.dart';

/// Pantalla para crear un nuevo pedido
/// 
/// Permite ingresar dirección de entrega, seleccionar ubicación en mapa,
/// calcular precio estimado y crear el pedido.
class NewOrderScreen extends ConsumerStatefulWidget {
  const NewOrderScreen({super.key});

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _dropoffStreetController = TextEditingController();
  final _dropoffCityController = TextEditingController();
  final _dropoffNameController = TextEditingController();
  final _dropoffPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Ubicación del comercio (pickup) - se carga del perfil
  String _pickupAddress = 'Cargando dirección...';
  GeoLocation? _pickupGeo;
  
  // Ubicación de entrega (dropoff)
  GeoLocation? _dropoffGeo;
  
  // Precio estimado
  double? _estimatedPrice;
  bool _isCalculating = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadMerchantAddress();
  }

  @override
  void dispose() {
    _dropoffStreetController.dispose();
    _dropoffCityController.dispose();
    _dropoffNameController.dispose();
    _dropoffPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Cargar dirección del comercio desde el perfil
  Future<void> _loadMerchantAddress() async {
    try {
      final merchantId = ref.read(merchantIdProvider);
      if (merchantId == null) return;
      
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('merchants').doc(merchantId).get();
      
      if (doc.exists && mounted) {
        final merchant = Merchant.fromJson(doc.data()!);
        setState(() {
          _pickupAddress = merchant.address.street;
          _pickupGeo = merchant.geo;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar dirección del comercio: $e');
      if (mounted) {
        setState(() {
          _pickupAddress = 'Dirección no disponible';
        });
      }
    }
  }

  /// Seleccionar ubicación en mapa
  Future<void> _selectLocationOnMap() async {
    final result = await Navigator.push<GeoLocation>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    
    if (result != null && mounted) {
      setState(() {
        _dropoffGeo = result;
      });
      
      // Geocodificar inverso para obtener dirección
      final address = await locationService.getAddressFromCoordinates(
        result.lat,
        result.lng,
      );
      
      if (address != null && mounted) {
        setState(() {
          _dropoffStreetController.text = address;
        });
      }
    }
  }

  /// Calcular precio estimado
  Future<void> _calculatePrice() async {
    if (_dropoffGeo == null || _pickupGeo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dirección de entrega')),
      );
      return;
    }
    
    setState(() {
      _isCalculating = true;
    });
    
    try {
      // Calcular distancia
      final distanceKm = locationService.calculateDistanceKm(
        _pickupGeo!.lat,
        _pickupGeo!.lng,
        _dropoffGeo!.lat,
        _dropoffGeo!.lng,
      );
      
      // Calcular precio (misma lógica que OrderService)
      final basePrice = 500.0;
      final pricePerKm = 150.0;
      final timeMin = (distanceKm / 30 * 60).ceil();
      final pricePerMin = 50.0;
      
      final total = basePrice + (distanceKm * pricePerKm) + (timeMin * pricePerMin);
      
      setState(() {
        _estimatedPrice = total;
      });
    } catch (e) {
      debugPrint('Error al calcular precio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al calcular precio')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }

  /// Crear pedido
  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dropoffGeo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la ubicación de entrega en el mapa')),
      );
      return;
    }
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      final orderService = OrderService(
        FirebaseFirestore.instance,
        ref.read(merchantIdProvider),
      );
      
      final order = await orderService.createOrder(
        pickupAddress: Address(
          street: _pickupAddress,
          city: '',
          state: '',
          country: 'Argentina',
          postalCode: '',
        ),
        pickupGeo: _pickupGeo!,
        dropoffAddress: Address(
          street: _dropoffStreetController.text,
          city: _dropoffCityController.text,
          state: '',
          country: 'Argentina',
          postalCode: '',
        ),
        dropoffGeo: _dropoffGeo!,
        dropoffName: _dropoffNameController.text.trim(),
        dropoffPhone: _dropoffPhoneController.text.trim().isEmpty 
            ? null 
            : _dropoffPhoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pedido creado exitosamente')),
        );
        context.go('/order/${order.id}');
      }
    } catch (e) {
      debugPrint('Error al crear pedido: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        backgroundColor: KatuyaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dirección de recogida
              KatuyaCard(
                child: Column(
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
                          child: const Icon(Icons.store, color: KatuyaColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Recogida en comercio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pickupAddress,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Dirección de entrega
              const Text(
                'Dirección de entrega',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              KatuyaTextField(
                controller: _dropoffStreetController,
                label: 'Calle y número',
                hint: 'Ej: Av. Corrientes 1234',
                prefixIcon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La dirección es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              KatuyaTextField(
                controller: _dropoffCityController,
                label: 'Ciudad/Barrio',
                hint: 'Ej: Buenos Aires',
                prefixIcon: Icons.location_city,
              ),
              const SizedBox(height: 12),
              
              // Botón para seleccionar en mapa
              OutlinedButton.icon(
                onPressed: _selectLocationOnMap,
                icon: Icon(Icons.map, color: KatuyaColors.primary),
                label: Text(
                  _dropoffGeo != null 
                      ? 'Ubicación seleccionada' 
                      : 'Seleccionar en mapa',
                  style: TextStyle(color: KatuyaColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: KatuyaColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              if (_dropoffGeo != null) ...[
                const SizedBox(height: 8),
                Text(
                  '📍 ${_dropoffGeo!.lat.toStringAsFixed(4)}, ${_dropoffGeo!.lng.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Datos del destinatario
              const Text(
                'Datos del destinatario',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              KatuyaTextField(
                controller: _dropoffNameController,
                label: 'Nombre',
                hint: 'Nombre de quien recibe',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              KatuyaTextField(
                controller: _dropoffPhoneController,
                label: 'Teléfono (opcional)',
                hint: 'Ej: 11 1234 5678',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              
              KatuyaTextField(
                controller: _notesController,
                label: 'Notas (opcional)',
                hint: 'Instrucciones adicionales',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Botón calcular precio
              KatuyaButton(
                text: _isCalculating ? 'Calculando...' : 'Calcular precio',
                onPressed: _isCalculating || _isCreating ? null : _calculatePrice,
                variant: ButtonVariant.outlined,
              ),
              
              // Precio estimado
              if (_estimatedPrice != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KatuyaColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KatuyaColors.secondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Precio estimado:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '\$${_estimatedPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Botón crear pedido
              KatuyaButton(
                text: _isCreating ? 'Creando pedido...' : 'Crear pedido',
                onPressed: _isCreating || _isCalculating || _estimatedPrice == null 
                    ? null 
                    : _createOrder,
                isLoading: _isCreating,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
