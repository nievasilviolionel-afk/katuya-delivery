// Provider de pedidos para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_models/shared_models.dart';
import 'auth_provider.dart';

/// Filtro de estado de pedido
enum OrderStatusFilter {
  todos,
  creado,
  buscando,
  asignado,
  recogido,
  entregado,
  cancelado,
}

/// Estado del provider de pedidos
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final OrderStatusFilter filter;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.filter = OrderStatusFilter.todos,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    OrderStatusFilter? filter,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filter: filter ?? this.filter,
    );
  }
}

/// StreamProvider que escucha los pedidos del merchant actual
/// 
/// Escucha la colección `orders` donde `merchantId` coincide con el del usuario
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  final merchantId = ref.watch(merchantIdProvider);
  
  // Si no hay merchantId, retornar stream vacío
  if (merchantId == null) {
    return Stream.value([]);
  }

  // Consultar pedidos del merchant ordenados por fecha descendente
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('merchantId', isEqualTo: merchantId)
      .orderBy('createdAt', descending: true)
      .limit(50);

  return query.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => Order.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }).onError<Object>((error, stackTrace) {
    debugPrint('Error al obtener pedidos: $error');
    return [];
  });
});

/// StreamProvider filtrado por estado
final filteredOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final orders = ref.watch(ordersStreamProvider);
  final filter = ref.watch(ordersFilterProvider);

  return orders.when(
    data: (orderList) {
      switch (filter) {
        case OrderStatusFilter.todos:
          return orderList;
        case OrderStatusFilter.creado:
          return orderList.where((o) => o.status == 'created').toList();
        case OrderStatusFilter.buscando:
          return orderList.where((o) => o.status == 'searching').toList();
        case OrderStatusFilter.asignado:
          return orderList.where((o) => o.status == 'assigned').toList();
        case OrderStatusFilter.recogido:
          return orderList.where((o) => o.status == 'picked_up').toList();
        case OrderStatusFilter.entregado:
          return orderList.where((o) => o.status == 'delivered').toList();
        case OrderStatusFilter.cancelado:
          return orderList.where((o) => o.status == 'cancelled').toList();
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider para el filtro seleccionado
final ordersFilterProvider = StateProvider<OrderStatusFilter>((ref) {
  return OrderStatusFilter.todos;
});

/// Provider para contar pedidos por estado
final ordersCountProvider = Provider<Map<String, int>>((ref) {
  final orders = ref.watch(ordersStreamProvider).value ?? [];
  
  final counts = <String, int>{
    'todos': orders.length,
    'creado': 0,
    'buscando': 0,
    'asignado': 0,
    'recogido': 0,
    'entregado': 0,
    'cancelado': 0,
  };
  
  for (final order in orders) {
    switch (order.status) {
      case 'created':
        counts['creado'] = (counts['creado'] ?? 0) + 1;
        break;
      case 'searching':
        counts['buscando'] = (counts['buscando'] ?? 0) + 1;
        break;
      case 'assigned':
        counts['asignado'] = (counts['asignado'] ?? 0) + 1;
        break;
      case 'picked_up':
        counts['recogido'] = (counts['recogido'] ?? 0) + 1;
        break;
      case 'delivered':
        counts['entregado'] = (counts['entregado'] ?? 0) + 1;
        break;
      case 'cancelled':
        counts['cancelado'] = (counts['cancelado'] ?? 0) + 1;
        break;
    }
  }
  
  return counts;
});

/// Provider para obtener un pedido específico por ID
final orderByIdProvider = FutureProvider.family<Order, String>((ref, orderId) async {
  final doc = await FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .get();
  
  if (!doc.exists) {
    throw Exception('Pedido no encontrado');
  }
  
  return Order.fromJson({...doc.data()!, 'id': doc.id});
});

/// Provider para pedidos activos (no entregados ni cancelados)
final activeOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersStreamProvider).value ?? [];
  return orders.where((o) {
    return o.status != 'delivered' && o.status != 'cancelled';
  }).toList();
});

/// Provider para el último pedido creado
final lastOrderProvider = Provider<Order?>((ref) {
  final orders = ref.watch(ordersStreamProvider).value ?? [];
  if (orders.isEmpty) return null;
  return orders.first;
});
