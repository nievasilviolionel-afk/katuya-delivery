// Pantalla de Detalle de Pedido para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:intl/intl.dart';

import '../providers/orders_provider.dart';
import '../services/order_service.dart';

/// Pantalla de detalle de un pedido específico
/// 
/// Muestra mapa con ubicación del repartidor, timeline del pedido,
/// información del repartidor y acciones disponibles.
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        backgroundColor: KatuyaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Compartir pedido
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función no implementada')),
              );
            },
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return _buildNotFoundView();
          }
          return _buildContent(order);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error),
      ),
    );
  }

  /// Construir contenido principal
  Widget _buildContent(Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado del pedido
          _buildStatusHeader(order),
          
          const SizedBox(height: 24),
          
          // Mapa (placeholder - en producción mostraría Google Maps)
          _buildMapPlaceholder(order),
          
          const SizedBox(height: 24),
          
          // Timeline del pedido
          _buildTimeline(order),
          
          const SizedBox(height: 24),
          
          // Información del repartidor (si está asignado)
          if (order.assignedDriverId != null) ...[
            _buildDriverCard(order),
            const SizedBox(height: 24),
          ],
          
          // Direcciones
          _buildAddressesCard(order),
          
          const SizedBox(height: 24),
          
          // Pricing
          _buildPricingCard(order),
          
          const SizedBox(height: 24),
          
          // Botones de acción
          _buildActionButtons(order),
        ],
      ),
    );
  }

  /// Construir header con estado
  Widget _buildStatusHeader(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(order.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(order.status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(order.status),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${order.id.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          KatuyaStatusBadge(status: order.status),
        ],
      ),
    );
  }

  /// Construir placeholder del mapa
  Widget _buildMapPlaceholder(Order order) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Mapa en tiempo real',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (order.assignedDriverId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ubicación del repartidor',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          // En producción, aquí iría GoogleMaps widget
        ],
      ),
    );
  }

  /// Construir timeline del pedido
  Widget _buildTimeline(Order order) {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial del pedido',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...order.timeline.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == order.timeline.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Línea vertical y punto
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(event.status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Contenido del evento
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(event.status),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatEventDate(event.ts),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Construir tarjeta del repartidor
  Widget _buildDriverCard(Order order) {
    // En producción, obtener datos del driver desde Firestore
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repartidor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: KatuyaColors.primary.withOpacity(0.1),
                child: Icon(Icons.person, color: KatuyaColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cargando datos...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '5.0',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  // TODO: Navegar a chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat no implementado')),
                  );
                },
                tooltip: 'Chatear',
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined),
                onPressed: () {
                  // TODO: Llamar al repartidor
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Llamada no implementada')),
                  );
                },
                tooltip: 'Llamar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir tarjeta de direcciones
  Widget _buildAddressesCard(Order order) {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Direcciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAddressRow(
            icon: Icons.store,
            label: 'Recogida',
            address: order.pickup.address.street,
            color: KatuyaColors.primary,
          ),
          const SizedBox(height: 16),
          _buildAddressRow(
            icon: Icons.home,
            label: 'Entrega',
            address: order.dropoff.address.street,
            color: KatuyaColors.accent,
          ),
          if (order.dropoff.name != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  order.dropoff.name!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
          if (order.dropoff.phone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  order.dropoff.phone!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Construir fila de dirección
  Widget _buildAddressRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir tarjeta de pricing
  Widget _buildPricingCard(Order order) {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Base', '\$${order.pricing.base.toStringAsFixed(2)}'),
          _buildPriceRow('Distancia (${order.pricing.distanceKm.toStringAsFixed(2)} km)', '\$${(order.pricing.distanceKm * 150).toStringAsFixed(2)}'),
          _buildPriceRow('Tiempo (${order.pricing.timeMin} min)', '\$${(order.pricing.timeMin * 50).toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildPriceRow(
            'Total',
            '\$${order.pricing.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Construir fila de precio
  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? null : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? KatuyaColors.primary : null,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir botones de acción
  Widget _buildActionButtons(Order order) {
    // Solo se puede cancelar si está en estado 'created' o 'searching'
    final canCancel = order.status == 'created' || order.status == 'searching';
    
    if (!canCancel) return const SizedBox.shrink();
    
    return KatuyaButton(
      text: 'Cancelar pedido',
      onPressed: () => _confirmCancel(order),
      variant: ButtonVariant.outlined,
      textColor: Colors.red,
      borderColor: Colors.red,
    );
  }

  /// Confirmar cancelación
  void _confirmCancel(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cancelar pedido'),
          ],
        ),
        content: const Text('¿Estás seguro que deseas cancelar este pedido? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, mantener'),
          ),
          KatuyaButton(
            text: 'Sí, cancelar',
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(order);
            },
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  /// Cancelar pedido
  Future<void> _cancelOrder(Order order) async {
    try {
      final orderService = OrderService(
        FirebaseFirestore.instance,
        ref.read(merchantIdProvider),
      );
      
      await orderService.cancelOrder(order.id, 'Cancelado por el comercio');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pedido cancelado')),
        );
        ref.invalidate(orderByIdProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  /// Construir vista de no encontrado
  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Pedido no encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('El pedido ${widget.orderId} no existe', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          KatuyaButton(
            text: 'Volver',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }

  /// Construir vista de error
  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar pedido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('$error', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          KatuyaButton(
            text: 'Reintentar',
            onPressed: () => ref.invalidate(orderByIdProvider(widget.orderId)),
          ),
        ],
      ),
    );
  }

  /// Obtener color según estado
  Color _getStatusColor(String status) {
    switch (status) {
      case 'created':
        return Colors.blue;
      case 'searching':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'picked_up':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtener ícono según estado
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'created':
        return Icons.receipt_long;
      case 'searching':
        return Icons.search;
      case 'assigned':
        return Icons.directions_bike;
      case 'picked_up':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Obtener texto según estado
  String _getStatusText(String status) {
    switch (status) {
      case 'created':
        return 'Creado';
      case 'searching':
        return 'Buscando repartidor';
      case 'assigned':
        return 'Repartidor asignado';
      case 'picked_up':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  /// Formatear fecha del evento
  String _formatEventDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return '';
    }
    
    return DateFormat('dd/MM/yyyy HH:mm', 'es_AR').format(dt);
  }
}
