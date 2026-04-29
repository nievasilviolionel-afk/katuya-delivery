// Provider de autenticación para Katuya Comercio
// by Silvio Lionel Nieva

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_models/shared_models.dart';

/// Estado del provider de autenticación
class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isMerchant;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isMerchant = false,
  });

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isMerchant,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isMerchant: isMerchant ?? this.isMerchant,
    );
  }

  /// Estado inicial
  static const initial = AuthState();

  /// Estado de carga
  static const loading = AuthState(isLoading: true);

  /// Estado con error
  static AuthState error(String message) => AuthState(error: message);
}

/// Notifier que maneja el estado de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthNotifier(this._auth, this._firestore, this._googleSignIn)
      : super(AuthState.initial) {
    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Manejar cambios en el estado de autenticación de Firebase
  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      state = AuthState.initial;
      return;
    }

    try {
      // Obtener perfil del usuario desde Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final profile = UserProfile.fromJson(data);
        
        // Verificar si el usuario tiene rol de merchant
        final isMerchant = profile.rol == 'merchant' || 
                          data['claims']?['merchant'] == true;
        
        state = AuthState(
          user: user,
          profile: profile,
          isAuthenticated: true,
          isMerchant: isMerchant,
        );
      } else {
        // Usuario no tiene perfil en Firestore
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isMerchant: false,
        );
      }
    } catch (e) {
      debugPrint('Error al obtener perfil: $e');
      state = AuthState(
        user: user,
        isAuthenticated: true,
        isMerchant: false,
      );
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      state = AuthState.loading;
      
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // El listener _onAuthStateChanged actualizará el estado
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe un usuario con este email.';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta.';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido.';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada.';
          break;
        default:
          errorMessage = e.message ?? 'Error al iniciar sesión.';
      }
      
      state = AuthState.error(errorMessage);
      return false;
    } catch (e) {
      state = AuthState.error('Error inesperado: $e');
      return false;
    }
  }

  /// Registrar nuevo usuario con email y contraseña
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String displayName,
    String merchantId,
  ) async {
    try {
      state = AuthState.loading;
      
      // Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final user = credential.user;
      if (user == null) throw Exception('Error al crear usuario');
      
      // Actualizar display name
      await user.updateDisplayName(displayName);
      
      // Crear perfil en Firestore
      final profile = UserProfile(
        id: user.uid,
        email: email.trim(),
        displayName: displayName,
        phone: '',
        rol: 'merchant',
        merchantId: merchantId,
        photoUrl: null,
        driverStatus: null,
      );
      
      await _firestore.collection('users').doc(user.uid).set(
        profile.toJson(),
      );
      
      // El listener actualizará el estado
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Este email ya está registrado.';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil.';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido.';
          break;
        default:
          errorMessage = e.message ?? 'Error al registrar.';
      }
      
      state = AuthState.error(errorMessage);
      return false;
    } catch (e) {
      state = AuthState.error('Error inesperado: $e');
      return false;
    }
  }

  /// Iniciar sesión con Google
  Future<bool> signInWithGoogle() async {
    try {
      state = AuthState.loading;
      
      // Iniciar flujo de Google Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = AuthState.error('Inicio con Google cancelado');
        return false;
      }
      
      // Obtener credenciales de Google
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Iniciar sesión en Firebase con credenciales de Google
      await _auth.signInWithCredential(credential);
      
      // El listener actualizará el estado
      return true;
    } catch (e) {
      state = AuthState.error('Error con Google Sign-In: $e');
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      state = AuthState.initial;
    } catch (e) {
      state = AuthState.error('Error al cerrar sesión: $e');
    }
  }

  /// Recuperar contraseña
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(e.message ?? 'Error al recuperar contraseña');
      return false;
    }
  }

  /// Verificar si el usuario actual es merchant
  bool get isCurrentMerchant => state.isMerchant;
  
  /// Obtener el merchantId del usuario actual
  String? get currentMerchantId => state.profile?.merchantId;
}

/// Provider principal de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(
      scopes: ['email'],
      // Configuración para web
      signInOption: SignInOption.standard,
    ),
  );
});

/// Provider que indica si el usuario está autenticado como merchant
final isMerchantProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isMerchant;
});

/// Provider que devuelve el merchantId actual
final merchantIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).profile?.merchantId;
});
