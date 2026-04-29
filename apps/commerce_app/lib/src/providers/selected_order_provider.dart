// Provider para el pedido seleccionado
// by Silvio Lionel Nieva

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// StateNotifier para manejar el pedido seleccionado
class SelectedOrderNotifier extends StateNotifier<Order?> {
  SelectedOrderNotifier() : super(null);

  /// Establecer el pedido seleccionado
  void select(Order order) {
    state = order;
  }

  /// Limpiar el pedido seleccionado
  void clear() {
    state = null;
  }

  /// Actualizar el pedido seleccionado
  void update(Order order) {
    state = order;
  }
}

/// Provider para el pedido seleccionado
final selectedOrderProvider = StateNotifierProvider<SelectedOrderNotifier, Order?>((ref) {
  return SelectedOrderNotifier();
});

/// Provider auxiliar para verificar si hay un pedido seleccionado
final hasSelectedOrderProvider = Provider<bool>((ref) {
  return ref.watch(selectedOrderProvider) != null;
});
