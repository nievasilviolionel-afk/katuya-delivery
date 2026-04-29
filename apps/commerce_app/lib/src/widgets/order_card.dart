// Widget de tarjeta de pedido para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:intl/intl.dart';

/// Tarjeta que muestra información resumida de un pedido
/// 
/// Muestra:
/// - Dirección de recogida corta
/// - Dirección de entrega corta
/// - Estado con badge coloreado
/// - Precio total
/// - Fecha/hora del pedido
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KatuyaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado y hora
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              KatuyaStatusBadge(status: order.status),
              Text(
                _formatDate(order.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Direcciones
          _buildAddressRow(
            icon: Icons.store,
            address: _getShortAddress(order.pickup.address.street),
            color: KatuyaColors.primary,
            label: 'Recogida',
          ),
          
          const SizedBox(height: 8),
          
          // Flecha indicadora
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Icon(
              Icons.arrow_downward,
              size: 16,
              color: Colors.grey[400],
            ),
          ),
          
          const SizedBox(height: 8),
          
          _buildAddressRow(
            icon: Icons.home,
            address: _getShortAddress(order.dropoff.address.street),
            color: KatuyaColors.accent,
            label: 'Entrega',
          ),
          
          const SizedBox(height: 16),
          
          // Footer con precio e ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                '\$${order.pricing.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir fila de dirección
  Widget _buildAddressRow({
    required IconData icon,
    required String address,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                address,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Obtener dirección corta (primeras 40 caracteres)
  String _getShortAddress(String address) {
    if (address.length <= 40) return address;
    return '${address.substring(0, 40)}...';
  }

  /// Formatear fecha
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return '';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dt);
    
    // Si es hoy, mostrar solo la hora
    if (difference.inDays == 0) {
      return DateFormat('HH:mm', 'es_AR').format(dt);
    }
    
    // Si es esta semana, mostrar día y hora
    if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm', 'es_AR').format(dt);
    }
    
    // Si es más antiguo, mostrar fecha completa
    return DateFormat('dd/MM/yyyy', 'es_AR').format(dt);
  }
}
