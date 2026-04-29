// Widget de chip de estado para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';

/// Chip que muestra el estado de un pedido con color semántico
/// 
/// Estados soportados:
/// - created: Azul
/// - searching: Naranja
/// - assigned: Violeta
/// - picked_up: Teal
/// - delivered: Verde
/// - cancelled: Rojo
class StatusChip extends StatelessWidget {
  final String status;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getText(),
            style: TextStyle(
              color: _getColor(),
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtener color principal según estado
  Color _getColor() {
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

  /// Obtener color de fondo (más claro)
  Color _getBackgroundColor() {
    return _getColor().withOpacity(0.15);
  }

  /// Obtener texto legible según estado
  String _getText() {
    switch (status) {
      case 'created':
        return 'Creado';
      case 'searching':
        return 'Buscando';
      case 'assigned':
        return 'Asignado';
      case 'picked_up':
        return 'Recogido';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
