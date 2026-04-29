/**
 * Esquema de colores de Katuya
 * by Silvio Lionel Nieva
 * 
 * Define la paleta de colores de la marca:
 * - Primario: Violeta (#6B46C1)
 * - Secundario: Teal (#319795)
 * - Acento: Terracota (#C05621)
 * - Colores semánticos para superficies, fondos y estados
 */

import 'package:flutter/material.dart';

/// Paleta de colores principal de Katuya
class KatuyaColors {
  KatuyaColors._();

  /// Color primario - Violeta característico de la marca
  static const Color primary = Color(0xFF6B46C1);
  
  /// Variación más clara del primario
  static const Color primaryLight = Color(0xFF9F7AEA);
  
  /// Variación más oscura del primario
  static const Color primaryDark = Color(0xFF553C9A);
  
  /// Color secundario - Teal para elementos complementarios
  static const Color secondary = Color(0xFF319795);
  
  /// Variación más clara del secundario
  static const Color secondaryLight = Color(0xFF81E6D9);
  
  /// Variación más oscura del secundario
  static const Color secondaryDark = Color(0xFF285E61);
  
  /// Color de acento - Terracota para llamadas a la acción
  static const Color accent = Color(0xFFC05621);
  
  /// Variación más clara del acento
  static const Color accentLight = Color(0xFFED8936);
  
  /// Variación más oscura del acento
  static const Color accentDark = Color(0xFF9C4221);

  // Colores semánticos
  
  /// Color de superficie (fondos de tarjetas, dialogs)
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Color de superficie con elevación
  static const Color surfaceVariant = Color(0xFFF7FAFC);
  
  /// Color de fondo principal de la app
  static const Color background = Color(0xFFF8F9FA);
  
  /// Color de fondo alternativo
  static const Color backgroundVariant = Color(0xFFEDF2F7);
  
  /// Color para indicar error
  static const Color error = Color(0xFFE53E3E);
  
  /// Variación más clara del error
  static const Color errorLight = Color(0xFFFED7D7);
  
  /// Color para indicar éxito
  static const Color success = Color(0xFF48BB78);
  
  /// Variación más clara del éxito
  static const Color successLight = Color(0xFFC6F6D5);
  
  /// Color para indicar advertencia
  static const Color warning = Color(0xFFDD6B20);
  
  /// Variación más clara de advertencia
  static const Color warningLight = Color(0xFFFFF5F5);
  
  /// Color para información
  static const Color info = Color(0xFF4299E1);
  
  /// Variación más clara de información
  static const Color infoLight = Color(0xFFBEE3F8);

  // Colores de texto
  
  /// Color de texto principal
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  /// Color de texto sobre secundario
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  /// Color de texto sobre superficie
  static const Color onSurface = Color(0xFF1A202C);
  
  /// Color de texto secundario (menos énfasis)
  static const Color onSurfaceVariant = Color(0xFF718096);
  
  /// Color de texto deshabilitado
  static const Color onSurfaceDisabled = Color(0xFFA0AEC0);
  
  /// Color de texto sobre fondo
  static const Color onBackground = Color(0xFF1A202C);
  
  /// Color de texto sobre error
  static const Color onError = Color(0xFFFFFFFF);

  // Colores de bordes y divisores
  
  /// Color de borde estándar
  static const Color border = Color(0xFFE2E8F0);
  
  /// Color de borde suave
  static const Color borderLight = Color(0xFFEDF2F7);
  
  /// Color de divisor
  static const Color divider = Color(0xFFE2E8F0);

  // Sombras
  
  /// Color de sombra suave
  static const Color shadow = Color(0x1A000000);
  
  /// Color de sombra fuerte
  static const Color shadowStrong = Color(0x33000000);
}

/// Esquema de colores completo para Material Design 3
class KatuyaColorScheme {
  const KatuyaColorScheme({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onTertiary,
    required this.error,
    required this.errorContainer,
    required this.onError,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.shadow,
    required this.inverseSurface,
    required this.inverseOnSurface,
  });

  /// Color primario de la marca (Violeta)
  final Color primary;
  
  /// Contenedor primario (variación clara)
  final Color primaryContainer;
  
  /// Texto sobre color primario
  final Color onPrimary;
  
  /// Color secundario (Teal)
  final Color secondary;
  
  /// Contenedor secundario
  final Color secondaryContainer;
  
  /// Texto sobre color secundario
  final Color onSecondary;
  
  /// Color terciario (Terracota - Acento)
  final Color tertiary;
  
  /// Contenedor terciario
  final Color tertiaryContainer;
  
  /// Texto sobre color terciario
  final Color onTertiary;
  
  /// Color de error
  final Color error;
  
  /// Contenedor de error
  final Color errorContainer;
  
  /// Texto sobre color de error
  final Color onError;
  
  /// Color de superficie
  final Color surface;
  
  /// Variante de superficie
  final Color surfaceVariant;
  
  /// Texto sobre superficie
  final Color onSurface;
  
  /// Texto variante sobre superficie
  final Color onSurfaceVariant;
  
  /// Color de outline/borde
  final Color outline;
  
  /// Color de sombra
  final Color shadow;
  
  /// Superficie inversa
  final Color inverseSurface;
  
  /// Texto sobre superficie inversa
  final Color inverseOnSurface;

  /// Crea un esquema de colores claro de Katuya
  factory KatuyaColorScheme.light() {
    return const KatuyaColorScheme(
      primary: KatuyaColors.primary,
      primaryContainer: KatuyaColors.primaryLight,
      onPrimary: KatuyaColors.onPrimary,
      secondary: KatuyaColors.secondary,
      secondaryContainer: KatuyaColors.secondaryLight,
      onSecondary: KatuyaColors.onSecondary,
      tertiary: KatuyaColors.accent,
      tertiaryContainer: KatuyaColors.accentLight,
      onTertiary: Colors.white,
      error: KatuyaColors.error,
      errorContainer: KatuyaColors.errorLight,
      onError: KatuyaColors.onError,
      surface: KatuyaColors.surface,
      surfaceVariant: KatuyaColors.surfaceVariant,
      onSurface: KatuyaColors.onSurface,
      onSurfaceVariant: KatuyaColors.onSurfaceVariant,
      outline: KatuyaColors.border,
      shadow: KatuyaColors.shadow,
      inverseSurface: KatuyaColors.onSurface,
      inverseOnSurface: KatuyaColors.surface,
    );
  }

  /// Crea un esquema de colores oscuro de Katuya
  factory KatuyaColorScheme.dark() {
    return const KatuyaColorScheme(
      primary: KatuyaColors.primaryLight,
      primaryContainer: KatuyaColors.primary,
      onPrimary: KatuyaColors.primaryDark,
      secondary: KatuyaColors.secondaryLight,
      secondaryContainer: KatuyaColors.secondary,
      onSecondary: KatuyaColors.secondaryDark,
      tertiary: KatuyaColors.accentLight,
      tertiaryContainer: KatuyaColors.accent,
      onTertiary: Colors.black,
      error: KatuyaColors.errorLight,
      errorContainer: KatuyaColors.error,
      onError: KatuyaColors.error,
      surface: Color(0xFF1A202C),
      surfaceVariant: Color(0xFF2D3748),
      onSurface: Color(0xFFE2E8F0),
      onSurfaceVariant: Color(0xFFA0AEC0),
      outline: Color(0xFF4A5568),
      shadow: Color(0x66000000),
      inverseSurface: KatuyaColors.surface,
      inverseOnSurface: KatuyaColors.onSurface,
    );
  }

  /// Convierte a ColorScheme de Material Design
  ColorScheme toMaterialColorScheme({Brightness brightness = Brightness.light}) {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondary,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiary,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onError,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      shadow: shadow,
      inverseSurface: inverseSurface,
      inverseOnSurface: inverseOnSurface,
    );
  }
}

/// Extensión para obtener el tema de Katuya
extension KatuyaThemeExtension on BuildContext {
  /// Obtiene el esquema de colores de Katuya
  KatuyaColorScheme get katuyaColors => KatuyaColorScheme.light();
  
  /// Verifica si el tema actual es oscuro
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
