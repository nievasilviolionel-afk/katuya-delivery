/**
 * Providers de Firebase para Riverpod
 * by Silvio Lionel Nieva
 * 
 * Provee instancias singleton de los servicios de Firebase
 * y configuración para emuladores en desarrollo local.
 */

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuración para emuladores de Firebase (desarrollo local)
class FirebaseEmulatorConfig {
  const FirebaseEmulatorConfig({
    this.host = 'localhost',
    this.authPort = 9099,
    this.firestorePort = 8080,
    this.messagingPort = 9199,
    this.storagePort = 9199,
    this.useEmulators = false,
  });

  /// Host donde corren los emuladores
  final String host;

  /// Puerto del emulador de Authentication
  final int authPort;

  /// Puerto del emulador de Firestore
  final int firestorePort;

  /// Puerto del emulador de Cloud Messaging
  final int messagingPort;

  /// Puerto del emulador de Storage
  final int storagePort;

  /// Si true, usa los emuladores en lugar de producción
  final bool useEmulators;

  /// Configuración por defecto para desarrollo local
  static const FirebaseEmulatorConfig development = FirebaseEmulatorConfig(
    host: 'localhost',
    authPort: 9099,
    firestorePort: 8080,
    messagingPort: 9199,
    storagePort: 9199,
    useEmulators: true,
  );

  /// Configuración para producción (no usa emuladores)
  static const FirebaseEmulatorConfig production = FirebaseEmulatorConfig(
    useEmulators: false,
  );
}

/// Provider que devuelve la configuración de emuladores
final firebaseEmulatorConfigProvider = Provider<FirebaseEmulatorConfig>((ref) {
  // En desarrollo, usar emuladores
  // En producción, cambiar a FirebaseEmulatorConfig.production
  return FirebaseEmulatorConfig.development;
});

/// Provider para la instancia de FirebaseApp
final firebaseAppProvider = Provider<FirebaseApp>((ref) async {
  await Firebase.initializeApp();
  return Firebase.app();
});

/// Provider para la instancia de FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  final auth = FirebaseAuth.instance;
  
  // Configurar emulador si está habilitado
  final emulatorConfig = ref.watch(firebaseEmulatorConfigProvider);
  if (emulatorConfig.useEmulators) {
    auth.useAuthEmulator(emulatorConfig.host, emulatorConfig.authPort);
  }
  
  return auth;
});

/// Provider para la instancia de FirebaseFirestore
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;
  
  // Configurar emulador si está habilitado
  final emulatorConfig = ref.watch(firebaseEmulatorConfigProvider);
  if (emulatorConfig.useEmulators) {
    firestore.settings = Settings(
      host: '${emulatorConfig.host}:${emulatorConfig.firestorePort}',
      sslEnabled: false,
      persistenceEnabled: false,
    );
  } else {
    // Configuración para producción
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  return firestore;
});

/// Provider para la instancia de FirebaseMessaging
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  final messaging = FirebaseMessaging.instance;
  
  // Configurar emulador si está habilitado
  final emulatorConfig = ref.watch(firebaseEmulatorConfigProvider);
  if (emulatorConfig.useEmulators) {
    // Nota: El emulador de FCM requiere configuración adicional
    // messaging.useMessagingEmulator(emulatorConfig.host, emulatorConfig.messagingPort);
  }
  
  return messaging;
});

/// Provider para la instancia de FirebaseStorage
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  final storage = FirebaseStorage.instance;
  
  // Configurar emulador si está habilitado
  final emulatorConfig = ref.watch(firebaseEmulatorConfigProvider);
  if (emulatorConfig.useEmulators) {
    storage.useStorageEmulator(emulatorConfig.host, emulatorConfig.storagePort);
  }
  
  return storage;
});

/// Provider que indica si Firebase está inicializado
final firebaseInitializedProvider = FutureProvider<bool>((ref) async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    // Ya está inicializado o hubo un error
    return Firebase.apps.isNotEmpty;
  }
});

/// Provider que devuelve el usuario actual autenticado
final firebaseCurrentUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provider que indica si hay un usuario autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(firebaseCurrentUserProvider);
  return userAsync.value != null;
});

/// Provider con información del usuario autenticado
final currentUserProvider = Provider<User?>((ref) {
  final userAsync = ref.watch(firebaseCurrentUserProvider);
  return userAsync.value;
});
