/**
 * Utilidades de fecha y hora para Katuya
 * by Silvio Lionel Nieva
 * 
 * Funciones para formateo de fechas con localización es-AR
 * (español de Argentina) por defecto.
 */

import 'package:intl/intl.dart';

/// Configura la locale por defecto como español de Argentina
void initializeDateUtils() {
  Intl.defaultLocale = 'es_AR';
}

/// Formatea una fecha para mostrar en pedidos.
/// 
/// Formato: "dd MMM yyyy, HH:mm"
/// Ejemplo: "15 ene 2024, 14:30"
String formatOrderDate(DateTime date, {String? locale}) {
  final effectiveLocale = locale ?? 'es_AR';
  final format = DateFormat('dd MMM yyyy, HH:mm', effectiveLocale);
  return format.format(date);
}

/// Formatea una fecha relativa al momento actual.
/// 
/// Retorna strings como:
/// - "Ahora mismo"
/// - "Hace 5 minutos"
/// - "Hace 2 horas"
/// - "Hoy, 14:30"
/// - "Ayer, 09:00"
/// - "15 ene 2024"
String formatRelativeTime(DateTime date, {String? locale}) {
  final effectiveLocale = locale ?? 'es_AR';
  final now = DateTime.now();
  final difference = now.difference(date);
  
  // Si es en el futuro
  if (difference.isNegative) {
    return 'En breve';
  }
  
  final minutes = difference.inMinutes;
  final hours = difference.inHours;
  final days = difference.inDays;
  
  // Menos de un minuto
  if (minutes == 0) {
    return 'Ahora mismo';
  }
  
  // Menos de una hora
  if (minutes < 60) {
    return 'Hace $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
  }
  
  // Menos de 24 horas
  if (hours < 24) {
    if (hours == 1) {
      return 'Hace 1 hora';
    }
    return 'Hace $hours horas';
  }
  
  // Menos de 2 días (ayer)
  if (days < 2) {
    final timeFormat = DateFormat('HH:mm', effectiveLocale);
    return 'Ayer, ${timeFormat.format(date)}';
  }
  
  // Menos de una semana
  if (days < 7) {
    final dayFormat = DateFormat('EEEE', effectiveLocale);
    final timeFormat = DateFormat('HH:mm', effectiveLocale);
    final dayName = dayFormat.format(date).toLowerCase();
    return '$dayName.capitalize, ${timeFormat.format(date)}';
  }
  
  // Más de una semana: formato completo
  return formatOrderDate(date, locale: locale);
}

/// Formatea una duración en segundos a string legible.
/// 
/// Ejemplos:
/// - 45 -> "45 seg"
/// - 90 -> "1 min 30 seg"
/// - 3665 -> "1 h 1 min"
String formatDuration(int seconds, {String? locale}) {
  if (seconds < 0) {
    return '0 seg';
  }
  
  if (seconds < 60) {
    return '$seconds seg';
  }
  
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  
  if (minutes < 60) {
    if (remainingSeconds == 0) {
      return '$minutes min';
    }
    return '$minutes min $remainingSeconds seg';
  }
  
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  
  if (hours < 24) {
    if (remainingMinutes == 0) {
      return '$hours h';
    }
    return '$hours h $remainingMinutes min';
  }
  
  final days = hours ~/ 24;
  final remainingHours = hours % 24;
  
  if (remainingHours == 0) {
    return '$days d';
  }
  return '$days d $remainingHours h';
}

/// Formatea una duración para mostrar ETA estimado.
/// 
/// Similar a formatDuration pero optimizado para tiempos de entrega.
String formatETA(int seconds, {String? locale}) {
  if (seconds <= 0) {
    return 'Inmediato';
  }
  
  if (seconds < 60) {
    return 'Menos de 1 min';
  }
  
  final minutes = seconds ~/ 60;
  
  if (minutes < 60) {
    return '$minutes min';
  }
  
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  
  if (remainingMinutes == 0) {
    return '$hours h';
  }
  
  return '$hours h $remainingMinutes min';
}

/// Formatea una fecha para mostrar solo la hora.
String formatTime(DateTime date, {String? locale}) {
  final effectiveLocale = locale ?? 'es_AR';
  final format = DateFormat('HH:mm', effectiveLocale);
  return format.format(date);
}

/// Formatea una fecha para mostrar solo el día.
String formatDate(DateTime date, {String? locale}) {
  final effectiveLocale = locale ?? 'es_AR';
  final format = DateFormat('dd/MM/yyyy', effectiveLocale);
  return format.format(date);
}

/// Formatea una fecha completa con día de la semana.
String formatFullDate(DateTime date, {String? locale}) {
  final effectiveLocale = locale ?? 'es_AR';
  final format = DateFormat('EEEE dd MMMM yyyy', effectiveLocale);
  return format.format(date).toLowerCase().capitalizeFirst();
}

/// Verifica si una fecha es hoy.
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

/// Verifica si una fecha es ayer.
bool isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day;
}

/// Extensión para facilitar el formateo de DateTime
extension DateTimeFormatting on DateTime {
  /// Formatea como fecha de pedido
  String toOrderDateString({String? locale}) =>
      formatOrderDate(this, locale: locale);
  
  /// Formatea como tiempo relativo
  String toRelativeTimeString({String? locale}) =>
      formatRelativeTime(this, locale: locale);
  
  /// Formatea solo la hora
  String toTimeString({String? locale}) =>
      formatTime(this, locale: locale);
  
  /// Formatea solo la fecha
  String toDateString({String? locale}) =>
      formatDate(this, locale: locale);
  
  /// Verifica si es hoy
  bool get isToday => DateTimeFormatting.isToday(this);
  
  /// Verifica si es ayer
  bool get isYesterday => DateTimeFormatting.isYesterday(this);
}

/// Helper para capitalizar la primera letra
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  String capitalizeFirst() {
    return replaceAllMapped(
      RegExp(r'\b\w'),
      (match) => match.group(0)!.toUpperCase(),
    );
  }
}
