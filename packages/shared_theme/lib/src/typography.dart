/**
 * Tipografía de Katuya
 * by Silvio Lionel Nieva
 * 
 * Define los estilos tipográficos para Material Design 3
 * usando la familia de fuentes Inter.
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clase que define el TextTheme de Katuya
class KatuyaTypography {
  KatuyaTypography._();

  /// Crea un TextTheme completo basado en Material 3
  static TextTheme createTextTheme({
    TextTheme? base,
    Color? color,
    Color? headlineColor,
    Color? bodyColor,
  }) {
    final baseTheme = base ?? ThemeData.light().textTheme;
    final primaryColor = color ?? const Color(0xFF1A202C);
    final headlineClr = headlineColor ?? primaryColor;
    final bodyClr = bodyColor ?? primaryColor;

    // Usamos Inter como fuente principal mediante Google Fonts
    final interStyle = GoogleFonts.interTextTheme(baseTheme);

    return interStyle.copyWith(
      // Display styles - Para títulos grandes y destacados
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        letterSpacing: -0.25,
        color: headlineClr,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
        color: headlineClr,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
        color: headlineClr,
      ),

      // Headline styles - Para encabezados de sección
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: headlineClr,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
        color: headlineClr,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: headlineClr,
      ),

      // Title styles - Para títulos de componentes
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
        color: headlineClr,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.50,
        letterSpacing: 0.15,
        color: headlineClr,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.10,
        color: headlineClr,
      ),

      // Body styles - Para contenido principal
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: 0.50,
        color: bodyClr,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
        color: bodyClr,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.40,
        color: bodyClr,
      ),

      // Label styles - Para etiquetas y botones
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.10,
        color: primaryColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.50,
        color: primaryColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.50,
        color: primaryColor,
      ),
    );
  }

  /// Crea un TextTheme para tema oscuro
  static TextTheme createDarkTextTheme() {
    return createTextTheme(
      color: const Color(0xFFE2E8F0),
      headlineColor: const Color(0xFFF7FAFC),
      bodyColor: const Color(0xFFCBD5E0),
    );
  }
}

/// Extensión para obtener tipografía de Katuya
extension KatuyaTypographyExtension on BuildContext {
  /// Obtiene el TextTheme de Katuya
  TextTheme get katuyaTypography => KatuyaTypography.createTextTheme();
}
