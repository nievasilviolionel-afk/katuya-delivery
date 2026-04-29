// Router principal de la app Katuya Comercio
// by Silvio Lionel Nieva

import 'package:go_router/go_router.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/new_order_screen.dart';
import 'src/screens/order_detail_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/about_screen.dart';

/// Configuración de rutas usando go_router
/// 
/// Rutas disponibles:
/// - `/` → SplashScreen (pantalla de carga inicial)
/// - `/auth` → AuthScreen (login y registro)
/// - `/home` → HomeScreen (lista de pedidos)
/// - `/new-order` → NewOrderScreen (crear nuevo pedido)
/// - `/order/:orderId` → OrderDetailScreen (detalle de pedido)
/// - `/settings` → SettingsScreen (configuración del comercio)
/// - `/about` → AboutScreen (información de la app)
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // Ruta inicial - Splash Screen
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // Autenticación
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    
    // Home - Lista de pedidos
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    
    // Crear nuevo pedido
    GoRoute(
      path: '/new-order',
      name: 'new-order',
      builder: (context, state) => const NewOrderScreen(),
    ),
    
    // Detalle de pedido
    GoRoute(
      path: '/order/:orderId',
      name: 'order-detail',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderDetailScreen(orderId: orderId);
      },
    ),
    
    // Configuración
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    
    // Acerca de
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
  
  // Manejo de errores de ruta
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Error'),
      backgroundColor: const Color(0xFF7C3AED),
      foregroundColor: const Color(0xFFFFFFFF),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),
          const Text(
            'Página no encontrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La ruta ${state.uri.path} no existe',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  ),
);
