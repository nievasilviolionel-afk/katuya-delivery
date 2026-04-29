// Pantalla de Configuración para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';

/// Pantalla de configuración del comercio
/// 
/// Permite ajustar:
/// - Auto-asignación de repartidores
/// - Radio máximo de entrega
/// - Timeout de cancelación automática
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Valores de configuración (en producción, cargar desde Firestore)
  bool _autoAssign = false;
  double _deliveryRadius = 5.0; // km
  int _cancelTimeout = 30; // minutos

  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: KatuyaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-asignación
            _buildAutoAssignSection(),
            
            const SizedBox(height: 24),
            
            // Radio de entrega
            _buildDeliveryRadiusSection(),
            
            const SizedBox(height: 24),
            
            // Timeout de cancelación
            _buildCancelTimeoutSection(),
            
            const SizedBox(height: 32),
            
            // Botón guardar
            if (_hasChanges)
              KatuyaButton(
                text: 'Guardar cambios',
                onPressed: _saveSettings,
              ),
            
            const SizedBox(height: 16),
            
            // Información adicional
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  /// Sección de auto-asignación
  Widget _buildAutoAssignSection() {
    return KatuyaCard(
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
                child: const Icon(Icons.auto_fix_high, color: KatuyaColors.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'Auto-asignación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cuando está activado, los pedidos se asignan automáticamente al repartidor más cercano disponible.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _autoAssign,
            onChanged: (value) {
              setState(() {
                _autoAssign = value;
                _hasChanges = true;
              });
            },
            activeColor: KatuyaColors.primary,
            title: Text(_autoAssign ? 'Activada' : 'Desactivada'),
            subtitle: const Text('Asignación automática de repartidores'),
          ),
        ],
      ),
    );
  }

  /// Sección de radio de entrega
  Widget _buildDeliveryRadiusSection() {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KatuyaColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.radio_button_checked, color: KatuyaColors.secondary),
              ),
              const SizedBox(width: 12),
              const Text(
                'Radio de entrega',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Distancia máxima desde el comercio para aceptar pedidos.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          // Slider
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _deliveryRadius,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${_deliveryRadius.toStringAsFixed(1)} km',
                  activeColor: KatuyaColors.secondary,
                  onChanged: (value) {
                    setState(() {
                      _deliveryRadius = value;
                      _hasChanges = true;
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: KatuyaColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_deliveryRadius.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: KatuyaColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          
          // Indicadores visuales
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 km', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text('20 km', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de timeout de cancelación
  Widget _buildCancelTimeoutSection() {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KatuyaColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer_outlined, color: KatuyaColors.accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Timeout de cancelación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tiempo máximo de espera antes de cancelar automáticamente un pedido sin repartidor asignado.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          // Selector de tiempo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [10, 15, 20, 30, 45, 60].map((minutes) {
              final isSelected = _cancelTimeout == minutes;
              return ChoiceChip(
                label: Text('$minutes min'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _cancelTimeout = minutes;
                      _hasChanges = true;
                    });
                  }
                },
                selectedColor: KatuyaColors.accent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Sección de información
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estos ajustes se aplicarán a todos los nuevos pedidos. Los pedidos existentes no se verán afectados.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Guardar configuración
  Future<void> _saveSettings() async {
    try {
      // En producción, guardar en Firestore
      // await FirebaseFirestore.instance.collection('merchants').doc(merchantId).update({
      //   'settings.autoAssign': _autoAssign,
      //   'settings.deliveryRadiusKm': _deliveryRadius,
      //   'settings.cancelTimeoutMinutes': _cancelTimeout,
      // });
      
      setState(() {
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar configuración: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al guardar configuración'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
