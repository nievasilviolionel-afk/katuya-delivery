// Pantalla de Splash para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_theme/shared_theme.dart';

import '../providers/auth_provider.dart';

/// Pantalla de carga inicial que muestra el logo de Katuya
/// 
/// Muestra el logo, la frase "Send it fast" y la firma "by Silvio Lionel Nieva".
/// Después de 2 segundos, redirige según el estado de autenticación.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  /// Navegar después de un delay de 2 segundos
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Verificar estado de autenticación
    final authState = ref.read(authProvider);
    
    if (authState.isAuthenticated) {
      // Usuario autenticado - verificar si es merchant
      if (authState.isMerchant) {
        context.go('/home');
      } else {
        // Usuario no es merchant - mostrar error y volver a auth
        _showNotMerchantDialog();
      }
    } else {
      // Usuario no autenticado
      context.go('/auth');
    }
  }

  /// Mostrar diálogo indicando que el usuario no es merchant
  void _showNotMerchantDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Acceso denegado'),
          ],
        ),
        content: const Text(
          'Esta cuenta no tiene permisos de comercio. Por favor, inicia sesión con una cuenta de merchant.',
        ),
        actions: [
          KatuyaButton(
            text: 'Cerrar sesión',
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.of(context).pop();
              context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KatuyaColors.primary,
              KatuyaColors.primary.withOpacity(0.8),
              const Color(0xFF6D28D9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de Katuya
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.delivery_dining,
                      size: 70,
                      color: KatuyaColors.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Nombre de la app
                const Text(
                  'Katuya Comercio',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Frase "Send it fast"
                Text(
                  'Send it fast',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Indicador de carga
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                
                const Spacer(),
                
                // Firma "by Silvio Lionel Nieva"
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'by Silvio Lionel Nieva',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
