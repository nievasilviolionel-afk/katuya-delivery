// Opciones de configuración de Firebase para Katuya Comercio
// by Silvio Lionel Nieva
//
// NOTA: Reemplaza los valores de placeholder con tus credenciales reales de Firebase.
// Para desarrollo local, los emuladores se configuran en main.dart.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de Firebase por defecto.
/// Usa placeholders que deben ser reemplazados con valores reales.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está soportado para Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está soportado para Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está soportado para esta plataforma.',
        );
    }
  }

  /// Configuración para Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '\${FIREBASE_WEB_API_KEY}',
    appId: '\${FIREBASE_WEB_APP_ID}',
    messagingSenderId: '\${FIREBASE_MESSAGING_SENDER_ID}',
    projectId: '\${FIREBASE_PROJECT_ID}',
    authDomain: '\${FIREBASE_AUTH_DOMAIN}',
    storageBucket: '\${FIREBASE_STORAGE_BUCKET}',
  );

  /// Configuración para Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '\${FIREBASE_ANDROID_API_KEY}',
    appId: '\${FIREBASE_ANDROID_APP_ID}',
    messagingSenderId: '\${FIREBASE_MESSAGING_SENDER_ID}',
    projectId: '\${FIREBASE_PROJECT_ID}',
    storageBucket: '\${FIREBASE_STORAGE_BUCKET}',
  );

  /// Configuración para iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '\${FIREBASE_IOS_API_KEY}',
    appId: '\${FIREBASE_IOS_APP_ID}',
    messagingSenderId: '\${FIREBASE_MESSAGING_SENDER_ID}',
    projectId: '\${FIREBASE_PROJECT_ID}',
    storageBucket: '\${FIREBASE_STORAGE_BUCKET}',
    iosBundleId: 'com.katuya.commerce',
  );

  /// Configuración para macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '\${FIREBASE_MACOS_API_KEY}',
    appId: '\${FIREBASE_MACOS_APP_ID}',
    messagingSenderId: '\${FIREBASE_MESSAGING_SENDER_ID}',
    projectId: '\${FIREBASE_PROJECT_ID}',
    storageBucket: '\${FIREBASE_STORAGE_BUCKET}',
    iosBundleId: 'com.katuya.commerce.macos',
  );
}
