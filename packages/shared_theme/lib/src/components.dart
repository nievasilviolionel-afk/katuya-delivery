/**
 * Componentes UI compartidos de Katuya
 * by Silvio Lionel Nieva
 * 
 * Componentes reutilizables estilizados con la marca Katuya:
 * - KatuyaButton
 * - KatuyaCard
 * - KatuyaTextField
 * - KatuyaAppBar
 * - KatuyaStatusBadge
 */

import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'package:shared_models/shared_models.dart';

// ============================================================================
// KatuyaButton - Botón principal de la marca
// ============================================================================

/// Botón principal de Katuya con estilos de la marca.
/// 
/// Usa el color primario violeta por defecto, con variantes para
/// diferentes niveles de énfasis.
class KatuyaButton extends StatelessWidget {
  const KatuyaButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = KatuyaButtonVariant.primary,
    this.size = KatuyaButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
  });

  /// Función que se ejecuta al presionar el botón
  final VoidCallback? onPressed;

  /// Contenido del botón (texto o widget)
  final Widget child;

  /// Variante visual del botón
  final KatuyaButtonVariant variant;

  /// Tamaño del botón
  final KatuyaButtonSize size;

  /// Indica si el botón está en estado de carga
  final bool isLoading;

  /// Si true, el botón ocupa todo el ancho disponible
  final bool fullWidth;

  /// Ícono opcional a mostrar antes del texto
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = KatuyaColorScheme.light();
    
    Color? backgroundColor;
    Color? foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case KatuyaButtonVariant.primary:
        backgroundColor = isEnabled ? colors.primary : colors.outline;
        foregroundColor = KatuyaColors.onPrimary;
        break;
      case KatuyaButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        borderSide = BorderSide(color: colors.primary);
        break;
      case KatuyaButtonVariant.accent:
        backgroundColor = isEnabled ? colors.tertiary : colors.outline;
        foregroundColor = KatuyaColors.onPrimary;
        break;
      case KatuyaButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        break;
      case KatuyaButtonVariant.danger:
        backgroundColor = isEnabled ? KatuyaColors.error : colors.outline;
        foregroundColor = KatuyaColors.onError;
        break;
    }

    double horizontalPadding;
    double verticalPadding;
    double fontSize;

    switch (size) {
      case KatuyaButtonSize.small:
        horizontalPadding = 16;
        verticalPadding = 8;
        fontSize = 14;
        break;
      case KatuyaButtonSize.medium:
        horizontalPadding = 24;
        verticalPadding = 12;
        fontSize = 16;
        break;
      case KatuyaButtonSize.large:
        horizontalPadding = 32;
        verticalPadding = 16;
        fontSize = 18;
        break;
    }

    final buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor ?? colors.primary),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: fontSize + 4),
                  const SizedBox(width: 8),
                  child,
                ],
              )
            : child;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderSide ?? BorderSide.none,
          ),
          elevation: variant == KatuyaButtonVariant.primary ? 2 : 0,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          child: buttonChild,
        ),
      ),
    );
  }

  bool get isEnabled => !isLoading && onPressed != null;
}

enum KatuyaButtonVariant { primary, secondary, accent, text, danger }

enum KatuyaButtonSize { small, medium, large }

// ============================================================================
// KatuyaCard - Tarjeta con estilo de la marca
// ============================================================================

/// Tarjeta con estilo Katuya, sombra suave y bordes redondeados.
/// 
/// Ideal para mostrar información agrupada como pedidos, perfiles, etc.
class KatuyaCard extends StatelessWidget {
  const KatuyaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
    this.color,
    this.onTap,
    this.borderColor,
  });

  /// Contenido de la tarjeta
  final Widget child;

  /// Padding interno de la tarjeta
  final EdgeInsetsGeometry padding;

  /// Elevación (sombra) de la tarjeta
  final double elevation;

  /// Color de fondo personalizado
  final Color? color;

  /// Callback opcional para hacer la tarjeta clicable
  final VoidCallback? onTap;

  /// Color del borde opcional
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation,
      shadowColor: KatuyaColors.shadow,
      color: color ?? KatuyaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    return onTap != null ? InkWell(onTap: onTap, child: card) : card;
  }
}

// ============================================================================
// KatuyaTextField - Campo de texto temático
// ============================================================================

/// Campo de texto con bordes y colores de Katuya.
/// 
/// Incluye validación visual y estados (focus, error, disabled).
class KatuyaTextField extends StatelessWidget {
  const KatuyaTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  /// Controlador del campo de texto
  final TextEditingController? controller;

  /// Texto de la etiqueta flotante
  final String? labelText;

  /// Texto de sugerencia (placeholder)
  final String? hintText;

  /// Ícono al inicio del campo
  final IconData? prefixIcon;

  /// Ícono al final del campo
  final IconData? suffixIcon;

  /// Si true, oculta el texto (para contraseñas)
  final bool obscureText;

  /// Tipo de teclado a mostrar
  final TextInputType? keyboardType;

  /// Función validadora
  final String? Function(String?)? validator;

  /// Callback cuando el texto cambia
  final ValueChanged<String>? onChanged;

  /// Callback cuando se presiona enter/enviar
  final ValueChanged<String>? onSubmitted;

  /// Número máximo de líneas
  final int maxLines;

  /// Si false, deshabilita el campo
  final bool enabled;

  /// Si true, enfoca automáticamente al montar
  final bool autofocus;

  /// Capitalización del texto
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: maxLines,
      enabled: enabled,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        filled: true,
        fillColor: enabled ? KatuyaColors.surface : KatuyaColors.backgroundVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KatuyaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KatuyaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KatuyaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KatuyaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KatuyaColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: KatuyaColors.borderLight),
        ),
        labelStyle: const TextStyle(
          color: KatuyaColors.onSurfaceVariant,
          fontFamily: 'Inter',
        ),
        hintStyle: const TextStyle(
          color: KatuyaColors.onSurfaceDisabled,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ============================================================================
// KatuyaAppBar - AppBar con branding de Katuya
// ============================================================================

/// AppBar personalizada con logo y branding de Katuya.
/// 
/// Incluye el tooltip "by Silvio Lionel Nieva" en el título.
class KatuyaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KatuyaAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.actions,
    this.bottom,
    this.elevation = 2,
    this.backgroundColor,
  });

  /// Título personalizado (opcional)
  final String? title;

  /// Si true, muestra el botón de volver
  final bool showBackButton;

  /// Widgets de acción a la derecha
  final List<Widget>? actions;

  /// Widget opcional en la parte inferior del AppBar
  final PreferredSizeWidget? bottom;

  /// Elevación (sombra) del AppBar
  final double elevation;

  /// Color de fondo personalizado
  final Color? backgroundColor;

  @override
  Size get preferredSize => Size.fromHeight(bottom != null ? 112 : 56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor ?? KatuyaColors.primary,
      foregroundColor: KatuyaColors.onPrimary,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Volver',
            )
          : null,
      title: Tooltip(
        message: 'by Silvio Lionel Nieva',
        child: Text(
          title ?? 'Katuya',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

// ============================================================================
// KatuyaStatusBadge - Badge para estados de pedido
// ============================================================================

/// Badge que muestra el estado de un pedido con colores semánticos.
/// 
/// Mapea cada OrderStatus a un color y texto apropiado.
class KatuyaStatusBadge extends StatelessWidget {
  const KatuyaStatusBadge({
    super.key,
    required this.status,
    this.size = KatuyaBadgeSize.medium,
  });

  /// Estado del pedido a mostrar
  final OrderStatus status;

  /// Tamaño del badge
  final KatuyaBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    double fontSize;
    EdgeInsets padding;
    
    switch (size) {
      case KatuyaBadgeSize.small:
        fontSize = 11;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        break;
      case KatuyaBadgeSize.medium:
        fontSize = 13;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
      case KatuyaBadgeSize.large:
        fontSize = 15;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.icon != null) ...[
            Icon(config.icon, size: fontSize + 2, color: config.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return const _StatusConfig(
          label: 'Creado',
          backgroundColor: KatuyaColors.infoLight,
          borderColor: KatuyaColors.info,
          textColor: KatuyaColors.info,
          icon: Icons.new_releases_outlined,
        );
      case OrderStatus.searching:
        return const _StatusConfig(
          label: 'Buscando conductor',
          backgroundColor: KatuyaColors.warningLight,
          borderColor: KatuyaColors.warning,
          textColor: KatuyaColors.warning,
          icon: Icons.search,
        );
      case OrderStatus.assigned:
        return const _StatusConfig(
          label: 'Asignado',
          backgroundColor: KatuyaColors.primaryLight,
          borderColor: KatuyaColors.primary,
          textColor: KatuyaColors.primary,
          icon: Icons.check_circle_outline,
        );
      case OrderStatus.picked_up:
        return const _StatusConfig(
          label: 'En camino',
          backgroundColor: KatuyaColors.secondaryLight,
          borderColor: KatuyaColors.secondary,
          textColor: KatuyaColors.secondary,
          icon: Icons.local_shipping,
        );
      case OrderStatus.delivered:
        return const _StatusConfig(
          label: 'Entregado',
          backgroundColor: KatuyaColors.successLight,
          borderColor: KatuyaColors.success,
          textColor: KatuyaColors.success,
          icon: Icons.done_all,
        );
      case OrderStatus.canceled:
        return const _StatusConfig(
          label: 'Cancelado',
          backgroundColor: KatuyaColors.errorLight,
          borderColor: KatuyaColors.error,
          textColor: KatuyaColors.error,
          icon: Icons.cancel_outlined,
        );
      case OrderStatus.expired:
        return const _StatusConfig(
          label: 'Expirado',
          backgroundColor: KatuyaColors.backgroundVariant,
          borderColor: KatuyaColors.onSurfaceDisabled,
          textColor: KatuyaColors.onSurfaceVariant,
          icon: Icons.access_time,
        );
    }
  }
}

enum KatuyaBadgeSize { small, medium, large }

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;
}
