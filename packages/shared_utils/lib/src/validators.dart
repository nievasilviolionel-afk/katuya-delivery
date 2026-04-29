/**
 * Validadores de formularios para Katuya
 * by Silvio Lionel Nieva
 * 
 * Funciones validadoras reutilizables para formularios:
 * - Email
 * - Teléfono (formato Argentina)
 * - Requerido
 * - Longitud mínima/máxima
 * - Números
 */

/// Valida que un campo no esté vacío.
/// 
/// Retorna null si es válido, o un mensaje de error si está vacío.
String? validateRequired(String? value, {String fieldName = 'Este campo'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName es requerido';
  }
  return null;
}

/// Valida que un email tenga formato correcto.
/// 
/// Usa una expresión regular estándar para validar emails.
/// Retorna null si es válido, o un mensaje de error si no lo es.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El email es requerido';
  }
  
  final email = value.trim();
  
  // Expresión regular para validación de email
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  if (!emailRegex.hasMatch(email)) {
    return 'Ingresa un email válido';
  }
  
  return null;
}

/// Valida un teléfono en formato argentino.
/// 
/// Acepta los siguientes formatos:
/// - 11 1234 5678 (celular CABA)
/// - 011 1234 5678 (celular CABA con 0)
/// - +54 9 11 1234 5678 (formato internacional)
/// - 351 123 4567 (celular interior)
/// - 0351 123 4567 (celular interior con 0)
/// 
/// Retorna null si es válido, o un mensaje de error si no lo es.
String? validatePhoneAR(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El teléfono es requerido';
  }
  
  // Remover espacios, guiones y paréntesis
  final phone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  
  // Validar longitud (mínimo 8, máximo 15 caracteres numéricos)
  if (phone.length < 8 || phone.length > 15) {
    return 'Ingresa un teléfono válido';
  }
  
  // Debe contener solo números (y opcionalmente + al inicio)
  final cleanPhone = phone.replaceAll('+', '');
  if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
    return 'El teléfono solo debe contener números';
  }
  
  // Validar formato argentino
  // Puede empezar con 54 (código país) o 0 (larga distancia) o directamente el código de área
  if (cleanPhone.length >= 8 && cleanPhone.length <= 15) {
    return null;
  }
  
  return 'Ingresa un teléfono válido de Argentina';
}

/// Valida la longitud mínima de un string.
/// 
/// Retorna null si es válido, o un mensaje de error si es muy corto.
String? validateMinLength(
  String? value,
  int minLength, {
  String fieldName = 'Este campo',
}) {
  if (value == null || value.isEmpty) {
    return null; // Usar validateRequired para campos obligatorios
  }
  
  if (value.length < minLength) {
    return '$fieldName debe tener al menos $minLength caracteres';
  }
  
  return null;
}

/// Valida la longitud máxima de un string.
/// 
/// Retorna null si es válido, o un mensaje de error si es muy largo.
String? validateMaxLength(
  String? value,
  int maxLength, {
  String fieldName = 'Este campo',
}) {
  if (value == null || value.isEmpty) {
    return null;
  }
  
  if (value.length > maxLength) {
    return '$fieldName no puede exceder $maxLength caracteres';
  }
  
  return null;
}

/// Valida que un valor sea numérico.
/// 
/// Opcionalmente valida un rango mínimo y máximo.
String? validateNumber(
  String? value, {
  double? min,
  double? max,
  String fieldName = 'Este campo',
}) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  
  final number = double.tryParse(value.trim());
  
  if (number == null) {
    return '$fieldName debe ser un número';
  }
  
  if (min != null && number < min) {
    return '$fieldName debe ser mayor o igual a $min';
  }
  
  if (max != null && number > max) {
    return '$fieldName debe ser menor o igual a $max';
  }
  
  return null;
}

/// Valida que un valor sea un entero.
String? validateInteger(
  String? value, {
  int? min,
  int? max,
  String fieldName = 'Este campo',
}) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  
  final number = int.tryParse(value.trim());
  
  if (number == null) {
    return '$fieldName debe ser un número entero';
  }
  
  if (min != null && number < min) {
    return '$fieldName debe ser mayor o igual a $min';
  }
  
  if (max != null && number > max) {
    return '$fieldName debe ser menor o igual a $max';
  }
  
  return null;
}

/// Valida que un valor esté dentro de una lista de opciones.
String? validateOneOf<T>(
  T? value,
  List<T> options, {
  String fieldName = 'Este campo',
}) {
  if (value == null) {
    return '$fieldName es requerido';
  }
  
  if (!options.contains(value)) {
    return '$fieldName debe ser una de las opciones válidas';
  }
  
  return null;
}

/// Valida una contraseña con requisitos de seguridad.
/// 
/// Requisitos por defecto:
/// - Mínimo 8 caracteres
/// - Al menos 1 mayúscula
/// - Al menos 1 número
String? validatePassword(
  String? value, {
  int minLength = 8,
  bool requireUppercase = true,
  bool requireNumber = true,
  bool requireSpecialChar = false,
}) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es requerida';
  }
  
  if (value.length < minLength) {
    return 'La contraseña debe tener al menos $minLength caracteres';
  }
  
  if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(value)) {
    return 'La contraseña debe incluir al menos una letra mayúscula';
  }
  
  if (requireNumber && !RegExp(r'\d').hasMatch(value)) {
    return 'La contraseña debe incluir al menos un número';
  }
  
  if (requireSpecialChar && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    return 'La contraseña debe incluir al menos un carácter especial';
  }
  
  return null;
}

/// Valida que dos contraseñas coincidan.
String? validatePasswordConfirmation(
  String? value,
  String password, {
  String fieldName = 'La confirmación',
}) {
  if (value == null || value.isEmpty) {
    return 'Confirma tu contraseña';
  }
  
  if (value != password) {
    return 'Las contraseñas no coinciden';
  }
  
  return null;
}

/// Valida una URL.
String? validateUrl(String? value, {bool allowEmpty = false}) {
  if (value == null || value.trim().isEmpty) {
    if (allowEmpty) {
      return null;
    }
    return 'La URL es requerida';
  }
  
  final url = value.trim();
  
  // Expresión regular simple para URLs
  final urlRegex = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    caseSensitive: false,
  );
  
  if (!urlRegex.hasMatch(url)) {
    return 'Ingresa una URL válida';
  }
  
  return null;
}

/// Valida un CUIT/CUIL argentino.
/// 
/// Verifica formato XX-X-XXXXXXX-X o XXXXXXXXXXXX
String? validateCUIT(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El CUIT es requerido';
  }
  
  // Remover guiones y espacios
  final cuit = value.replaceAll(RegExp(r'[\s\-]'), '');
  
  // Debe tener 11 dígitos
  if (cuit.length != 11) {
    return 'El CUIT debe tener 11 dígitos';
  }
  
  // Debe ser solo números
  if (!RegExp(r'^\d+$').hasMatch(cuit)) {
    return 'El CUIT debe contener solo números';
  }
  
  // Validar formato básico (20, 23, 24, 27, 30, 33, 34 para códigos iniciales comunes)
  final prefix = cuit.substring(0, 2);
  const validPrefixes = ['20', '23', '24', '27', '30', '33', '34'];
  
  if (!validPrefixes.contains(prefix)) {
    return 'CUIT inválido';
  }
  
  // Aquí se podría agregar validación del dígito verificador
  // Por ahora, validación básica es suficiente
  
  return null;
}

/// Combina múltiples validadores en uno solo.
/// 
/// Ejecuta todos los validadores en orden y retorna el primer error encontrado.
String? validateMultiple(
  String? value,
  List<String? Function(String?)> validators,
) {
  for (final validator in validators) {
    final error = validator(value);
    if (error != null) {
      return error;
    }
  }
  return null;
}

/// Clase utilitaria para agrupar validadores comunes
class Validators {
  /// Validador para email requerido
  static final emailRequired = (String? value) =>
      validateMultiple(value, [validateRequired, validateEmail]);
  
  /// Validador para teléfono argentino requerido
  static final phoneRequired = (String? value) =>
      validateMultiple(value, [validateRequired, validatePhoneAR]);
  
  /// Validador para nombre (requerido, 2-50 caracteres)
  static final name = (String? value) => validateMultiple(
        value,
        [
          validateRequired,
          (v) => validateMinLength(v, 2, fieldName: 'El nombre'),
          (v) => validateMaxLength(v, 50, fieldName: 'El nombre'),
        ],
      );
  
  /// Validador para dirección requerida
  static final address = (String? value) => validateMultiple(
        value,
        [
          validateRequired,
          (v) => validateMinLength(v, 5, fieldName: 'La dirección'),
        ],
      );
}
