// Punto de entrada principal de Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'router.dart';
import 'src/providers/auth_provider.dart';
import 'shared_theme/shared_theme.dart';

/// Función principal de la aplicación
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configurar emuladores para desarrollo local (solo en debug)
  if (!kReleaseMode) {
    // Emulador de Firestore
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    
    // Emulador de Auth
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    
    print('🔧 Usando emuladores de Firebase para desarrollo');
  }
  
  // Configurar orientación de pantalla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const ProviderScope(child: KatuyaCommerceApp()));
}

/// Widget raíz de la aplicación Katuya Comercio
class KatuyaCommerceApp extends ConsumerWidget {
  const KatuyaCommerceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el estado de autenticación
    final authState = ref.watch(authProvider);
    
    return MaterialApp.router(
      title: 'Katuya Comercio',
      debugShowCheckedModeBanner: false,
      
      // Router configuration
      routerConfig: router,
      
      // Tema usando shared_theme
      theme: KatuyaTheme.lightTheme,
      darkTheme: KatuyaTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Localización - Español Argentina por defecto
      locale: const Locale('es', 'AR'),
      supportedLocales: const [
        Locale('es', 'AR'), // Español Argentina
        Locale('en', 'US'), // Inglés (soporte futuro)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
