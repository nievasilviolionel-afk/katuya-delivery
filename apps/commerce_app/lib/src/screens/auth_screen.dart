// Pantalla de Autenticación para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_theme/shared_theme.dart';
import 'shared_utils/validators.dart' as validators;

import '../providers/auth_provider.dart';

/// Pantalla de autenticación con login y registro
/// 
/// Permite iniciar sesión con email/contraseña o Google Sign-In.
/// Verifica que el usuario tenga rol de merchant.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _merchantIdController = TextEditingController();
  
  bool _isLogin = true; // true = login, false = registro
  bool _isLoading = false;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _merchantIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Manejar inicio de sesión
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Verificar si es merchant después de un pequeño delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authState = ref.read(authProvider);
      
      if (authState.isMerchant) {
        context.go('/home');
      } else {
        setState(() {
          _errorMessage = 'Esta cuenta no tiene permisos de comercio.';
        });
      }
    } else {
      final error = ref.read(authProvider).error;
      setState(() {
        _errorMessage = error ?? 'Error al iniciar sesión';
      });
    }
  }

  /// Manejar registro
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _merchantIdController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      setState(() {
        _errorMessage = error ?? 'Error al registrar';
      });
    }
  }

  /// Manejar login con Google
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authState = ref.read(authProvider);
      
      if (authState.isMerchant) {
        context.go('/home');
      } else {
        setState(() {
          _errorMessage = 'Esta cuenta de Google no tiene permisos de comercio.';
        });
      }
    } else {
      final error = ref.read(authProvider).error;
      setState(() {
        _errorMessage = error ?? 'Error con Google Sign-In';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Logo y título
                _buildHeader(),
                
                const SizedBox(height: 48),
                
                // Formulario
                _buildForm(),
                
                const SizedBox(height: 24),
                
                // Mensaje de error
                if (_errorMessage != null) _buildErrorMessage(),
                
                const SizedBox(height: 24),
                
                // Botón principal
                KatuyaButton(
                  text: _isLoading ? 'Cargando...' : (_isLogin ? 'Iniciar sesión' : 'Registrarse'),
                  onPressed: _isLoading ? null : (_isLogin ? _handleLogin : _handleSignUp),
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // Separador
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o continúa con',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón Google
                _buildGoogleButton(),
                
                const SizedBox(height: 24),
                
                // Toggle login/registro
                _buildToggleText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construir header con logo
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: KatuyaColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.delivery_dining,
            size: 50,
            color: KatuyaColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Katuya Comercio',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Send it fast',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Construir formulario
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo de nombre (solo registro)
          if (!_isLogin) ...[
            KatuyaTextField(
              controller: _nameController,
              label: 'Nombre completo',
              hint: 'Tu nombre',
              prefixIcon: Icons.person_outline,
              validator: (value) => validators.requiredValidator(value, 'El nombre es requerido'),
            ),
            const SizedBox(height: 16),
            
            // Campo de Merchant ID (solo registro)
            KatuyaTextField(
              controller: _merchantIdController,
              label: 'ID de Comercio',
              hint: 'Identificador de tu comercio',
              prefixIcon: Icons.store_outlined,
              validator: (value) => validators.requiredValidator(value, 'El ID de comercio es requerido'),
            ),
            const SizedBox(height: 16),
          ],
          
          // Campo de email
          KatuyaTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'tu@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: validators.emailValidator,
          ),
          const SizedBox(height: 16),
          
          // Campo de contraseña
          KatuyaTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: (value) => validators.minLengthValidator(value, 6, 'La contraseña debe tener al menos 6 caracteres'),
          ),
          
          // Olvidé mi contraseña (solo login)
          if (_isLogin) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implementar recuperación de contraseña
                  _showResetPasswordDialog();
                },
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construir mensaje de error
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir botón de Google
  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      icon: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
        height: 24,
        width: 24,
      ),
      label: const Text(
        'Continuar con Google',
        style: TextStyle(color: Colors.black87),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Construir texto de toggle login/registro
  Widget _buildToggleText() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: _isLogin ? '¿No tienes una cuenta? ' : '¿Ya tienes una cuenta? ',
          style: TextStyle(color: Colors.grey[600]),
          children: [
            TextSpan(
              text: _isLogin ? 'Regístrate' : 'Inicia sesión',
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _errorMessage = null;
                  });
                },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar diálogo de recuperación de contraseña
  void _showResetPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu email y te enviaremos instrucciones para recuperar tu contraseña.'),
            const SizedBox(height: 16),
            KatuyaTextField(
              controller: emailController,
              label: 'Email',
              hint: 'tu@email.com',
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          KatuyaButton(
            text: 'Enviar',
            onPressed: () async {
              if (validators.emailValidator(emailController.text) == null) {
                final success = await ref.read(authProvider.notifier).resetPassword(emailController.text);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email de recuperación enviado')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
