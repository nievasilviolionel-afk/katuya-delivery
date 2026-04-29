// Pantalla Home para Katuya Comercio - Lista de pedidos
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';

import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';

/// Pantalla principal con lista de pedidos
/// 
/// Muestra todos los pedidos del merchant con filtros por estado,
/// pull-to-refresh y FloatingActionButton para crear nuevo pedido.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final ordersAsync = ref.watch(filteredOrdersStreamProvider);
    final counts = ref.watch(ordersCountProvider).value ?? {};
    
    return Scaffold(
      appBar: KatuyaAppBar(
        title: 'Katuya Comercio',
        subtitle: authState.profile?.displayName ?? '',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Configuración',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push('/about'),
            tooltip: 'Acerca de',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros por estado
          _buildStatusFilters(counts),
          
          // Lista de pedidos
          Expanded(
            child: ordersAsync.when(
              data: (orders) => _buildOrdersList(orders),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorView(error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new-order'),
        backgroundColor: KatuyaColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Pedido'),
      ),
    );
  }

  /// Construir filtros de estado
  Widget _buildStatusFilters(Map<String, int> counts) {
    final currentFilter = ref.watch(ordersFilterProvider);
    final filterNotifier = ref.read(ordersFilterProvider.notifier);
    
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFilterChip(
            label: 'Todos',
            count: counts['todos'] ?? 0,
            isSelected: currentFilter == OrderStatusFilter.todos,
            onTap: () => filterNotifier.state = OrderStatusFilter.todos,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Creados',
            count: counts['creado'] ?? 0,
            isSelected: currentFilter == OrderStatusFilter.creado,
            onTap: () => filterNotifier.state = OrderStatusFilter.creado,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Buscando',
            count: counts['buscando'] ?? 0,
            isSelected: currentFilter == OrderStatusFilter.buscando,
            onTap: () => filterNotifier.state = OrderStatusFilter.buscando,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Asignados',
            count: counts['asignado'] ?? 0,
            isSelected: currentFilter == OrderStatusFilter.asignado,
            onTap: () => filterNotifier.state = OrderStatusFilter.asignado,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Recogidos',
            count: counts['recogido'] ?? 0,
            isSelected: currentFilter == OrderStatusFilter.recogido,
            onTap: () => filterNotifier.state = OrderStatusFilter.recogido,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Entregados',
            count: counts['entregado'] ?? 0,
            isSelected: currentFilter == OrderStatusFilter.entregado,
            onTap: () => filterNotifier.state = OrderStatusFilter.entregado,
          ),
        ],
      ),
    );
  }

  /// Construir chip de filtro
  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : KatuyaColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? KatuyaColors.primary : KatuyaColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      selectedColor: KatuyaColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Construir lista de pedidos
  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyView();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ordersStreamProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OrderCard(
              order: order,
              onTap: () => context.push('/order/${order.id}'),
            ),
          );
        },
      ),
    );
  }

  /// Construir vista vacía
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos aparecerán aquí',
            style: TextStyle(color: Colors.grey[500]),
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
          Text(
            'Error al cargar pedidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          KatuyaButton(
            text: 'Reintentar',
            onPressed: () => ref.invalidate(ordersStreamProvider),
          ),
        ],
      ),
    );
  }

  /// Confirmar cierre de sesión
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          KatuyaButton(
            text: 'Salir',
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.pop(context);
              context.go('/auth');
            },
          ),
        ],
      ),
    );
  }
}
