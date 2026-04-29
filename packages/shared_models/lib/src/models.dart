/**
 * Modelos compartidos de Katuya
 * by Silvio Lionel Nieva
 * 
 * Definición de todas las entidades del dominio usando Freezed y JSON serialization.
 */

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'models.freezed.dart';
part 'models.g.dart';

// ============================================================================
// Enums
// ============================================================================

/// Roles de usuario en el sistema Katuya
enum UserRole { admin, merchant, driver }

/// Estado del conductor
enum DriverStatus { offline, online, busy, suspended }

/// Estado de un pedido
enum OrderStatus {
  created,
  searching,
  assigned,
  picked_up,
  delivered,
  canceled,
  expired
}

/// Tipo de vehículo
enum VehicleType { bike, motorcycle, car }

/// Estado de una oferta
enum OfferState { sent, accepted, declined, expired }

/// Estado del comercio
enum MerchantStatus { active, paused }

// ============================================================================
// GeoPoint - Ubicación geográfica con geohash
// ============================================================================

@freezed
class GeoPoint with _$GeoPoint {
  const factory GeoPoint({
    required double lat,
    required double lng,
    required String geohash,
  }) = _GeoPoint;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);

  /// Crea un GeoPoint desde un DocumentSnapshot de Firestore
  factory GeoPoint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GeoPoint(
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      geohash: data['geohash'] as String,
    );
  }
}

// ============================================================================
// LocationDetail - Detalle de ubicación para pedidos
// ============================================================================

@freezed
class LocationDetail with _$LocationDetail {
  const factory LocationDetail({
    String? name,
    String? phone,
    required String address,
    required GeoPoint geo,
    String? notes,
  }) = _LocationDetail;

  factory LocationDetail.fromJson(Map<String, dynamic> json) =>
      _$LocationDetailFromJson(json);
}

// ============================================================================
// Pricing - Información de precios
// ============================================================================

@freezed
class Pricing with _$Pricing {
  const factory Pricing({
    required double base,
    required double distanceKm,
    required double timeMin,
    required double total,
    required String currency,
    double? surgeMultiplier,
  }) = _Pricing;

  factory Pricing.fromJson(Map<String, dynamic> json) => _$PricingFromJson(json);
}

// ============================================================================
// TimelineEvent - Evento en la línea de tiempo de un pedido
// ============================================================================

@freezed
class TimelineEvent with _$TimelineEvent {
  const factory TimelineEvent({
    required OrderStatus status,
    @TimestampConverter() required DateTime ts,
    required String by,
    String? note,
  }) = _TimelineEvent;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);

  /// Crea un evento con timestamp actual del servidor
  factory TimelineEvent.now({
    required OrderStatus status,
    required String by,
    String? note,
  }) {
    return TimelineEvent(
      status: status,
      ts: DateTime.now(),
      by: by,
      note: note,
    );
  }
}

// ============================================================================
// UserProfile - Perfil de usuario
// ============================================================================

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required UserRole role,
    String? merchantId,
    @Default(DriverStatus.offline) DriverStatus? driverStatus,
    required String phone,
    required String email,
    required String displayName,
    String? photoUrl,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Crea un perfil con timestamps automáticos
  factory UserProfile.create({
    required String uid,
    required UserRole role,
    String? merchantId,
    DriverStatus? driverStatus,
    required String phone,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    final now = DateTime.now();
    return UserProfile(
      uid: uid,
      role: role,
      merchantId: merchantId,
      driverStatus: driverStatus,
      phone: phone,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: now,
      updatedAt: now,
    );
  }
}

// ============================================================================
// MerchantSettings - Configuración del comercio
// ============================================================================

@freezed
class MerchantSettings with _$MerchantSettings {
  const factory MerchantSettings({
    @Default(false) bool autoAssign,
    @Default(10.0) double deliveryRadiusKm,
    @Default(300) int cancelTimeoutSec,
    @Default('ARS') String currency,
    @Default(500.0) double baseFare,
    @Default(100.0) double perKmRate,
    @Default(20.0) double perMinuteRate,
    @Default(300.0) double minimumFare,
    @Default(10.0) double serviceFeePercent,
    @Default(80.0) double driverPayoutPercent,
  }) = _MerchantSettings;

  factory MerchantSettings.fromJson(Map<String, dynamic> json) =>
      _$MerchantSettingsFromJson(json);
}

// ============================================================================
// Merchant - Comercio
// ============================================================================

@freezed
class Merchant with _$Merchant {
  const factory Merchant({
    required String id,
    required String name,
    required String legalName,
    String? taxId,
    required String address,
    required GeoPoint geo,
    required MerchantStatus status,
    required MerchantSettings settings,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _Merchant;

  factory Merchant.fromJson(Map<String, dynamic> json) =>
      _$MerchantFromJson(json);

  /// Crea un comercio con timestamps automáticos
  factory Merchant.create({
    required String id,
    required String name,
    required String legalName,
    String? taxId,
    required String address,
    required GeoPoint geo,
    MerchantStatus status = MerchantStatus.active,
    MerchantSettings? settings,
  }) {
    final now = DateTime.now();
    return Merchant(
      id: id,
      name: name,
      legalName: legalName,
      taxId: taxId,
      address: address,
      geo: geo,
      status: status,
      settings: settings ?? const MerchantSettings(),
      createdAt: now,
      updatedAt: now,
    );
  }
}

// ============================================================================
// Vehicle - Vehículo del conductor
// ============================================================================

@freezed
class Vehicle with _$Vehicle {
  const factory Vehicle({
    required VehicleType type,
    required String plate,
    String? color,
    String? model,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);
}

// ============================================================================
// DriverRatings - Calificaciones del conductor
// ============================================================================

@freezed
class DriverRatings with _$DriverRatings {
  const factory DriverRatings({
    @Default(0.0) double avg,
    @Default(0) int count,
  }) = _DriverRatings;

  factory DriverRatings.fromJson(Map<String, dynamic> json) =>
      _$DriverRatingsFromJson(json);
}

// ============================================================================
// DriverDocuments - Documentos del conductor
// ============================================================================

@freezed
class DriverDocuments with _$DriverDocuments {
  const factory DriverDocuments({
    String? dni,
    String? license,
    String? insurance,
    String? vehicleRegistration,
  }) = _DriverDocuments;

  factory DriverDocuments.fromJson(Map<String, dynamic> json) =>
      _$DriverDocumentsFromJson(json);
}

// ============================================================================
// LocationWithTimestamp - Ubicación con timestamp para conductor
// ============================================================================

@freezed
class LocationWithTimestamp with _$LocationWithTimestamp {
  const factory LocationWithTimestamp({
    required double lat,
    required double lng,
    required String geohash,
    @TimestampConverter() required DateTime ts,
  }) = _LocationWithTimestamp;

  factory LocationWithTimestamp.fromJson(Map<String, dynamic> json) =>
      _$LocationWithTimestampFromJson(json);
}

// ============================================================================
// Driver - Conductor
// ============================================================================

@freezed
class Driver with _$Driver {
  const factory Driver({
    required String id,
    required String userId,
    required Vehicle vehicle,
    @Default(false) bool online,
    LocationWithTimestamp? lastLocation,
    required DriverRatings ratings,
    required DriverDocuments documents,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _Driver;

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);

  /// Crea un conductor con timestamps automáticos
  factory Driver.create({
    required String id,
    required String userId,
    required Vehicle vehicle,
    DriverRatings? ratings,
    DriverDocuments? documents,
  }) {
    final now = DateTime.now();
    return Driver(
      id: id,
      userId: userId,
      vehicle: vehicle,
      online: false,
      ratings: ratings ?? const DriverRatings(),
      documents: documents ?? const DriverDocuments(),
      createdAt: now,
      updatedAt: now,
    );
  }
}

// ============================================================================
// Order - Pedido
// ============================================================================

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String merchantId,
    required String createdBy,
    required OrderStatus status,
    required LocationDetail pickup,
    required LocationDetail dropoff,
    required Pricing pricing,
    String? assignedDriverId,
    int? etaSec,
    @Default([]) List<TimelineEvent> timeline,
    String? chatId,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// Crea un pedido con timestamps automáticos
  factory Order.create({
    required String id,
    required String merchantId,
    required String createdBy,
    required LocationDetail pickup,
    required LocationDetail dropoff,
    required Pricing pricing,
    String? chatId,
  }) {
    final now = DateTime.now();
    final initialEvent = TimelineEvent(
      status: OrderStatus.created,
      ts: now,
      by: createdBy,
    );
    return Order(
      id: id,
      merchantId: merchantId,
      createdBy: createdBy,
      status: OrderStatus.created,
      pickup: pickup,
      dropoff: dropoff,
      pricing: pricing,
      timeline: [initialEvent],
      chatId: chatId,
      createdAt: now,
      updatedAt: now,
    );
  }
}

// ============================================================================
// Offer - Oferta a conductor
// ============================================================================

@freezed
class Offer with _$Offer {
  const factory Offer({
    required String id,
    required String orderId,
    required String driverId,
    required String merchantId,
    required OfferState state,
    @TimestampConverter() required DateTime sentAt,
    @TimestampConverter() required DateTime expiresAt,
    @TimestampConverter() DateTime? respondedAt,
    double? estimatedEarnings,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

  /// Crea una oferta que expira en 5 minutos por defecto
  factory Offer.create({
    required String id,
    required String orderId,
    required String driverId,
    required String merchantId,
    double? estimatedEarnings,
    int expiresInSeconds = 300,
  }) {
    final now = DateTime.now();
    return Offer(
      id: id,
      orderId: orderId,
      driverId: driverId,
      merchantId: merchantId,
      state: OfferState.sent,
      sentAt: now,
      expiresAt: now.add(Duration(seconds: expiresInSeconds)),
      estimatedEarnings: estimatedEarnings,
    );
  }
}

// ============================================================================
// ChatMessage - Mensaje de chat
// ============================================================================

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String chatId,
    required String senderId,
    required UserRole senderRole,
    required String content,
    @TimestampConverter() required DateTime sentAt,
    @Default(false) bool read,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// Crea un mensaje con timestamp automático
  factory ChatMessage.create({
    required String id,
    required String chatId,
    required String senderId,
    required UserRole senderRole,
    required String content,
  }) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderRole: senderRole,
      content: content,
      sentAt: DateTime.now(),
      read: false,
    );
  }
}

// ============================================================================
// Rating - Calificación
// ============================================================================

@freezed
class Rating with _$Rating {
  const factory Rating({
    required String id,
    required String orderId,
    required UserRole fromRole,
    required String fromId,
    required String toId,
    required UserRole toRole,
    required int score,
    String? comment,
    @TimestampConverter() required DateTime createdAt,
  }) = _Rating;

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);

  /// Crea una calificación con timestamp automático
  factory Rating.create({
    required String id,
    required String orderId,
    required UserRole fromRole,
    required String fromId,
    required String toId,
    required UserRole toRole,
    required int score,
    String? comment,
  }) {
    return Rating(
      id: id,
      orderId: orderId,
      fromRole: fromRole,
      fromId: fromId,
      toId: toId,
      toRole: toRole,
      score: score.clamp(1, 5),
      comment: comment,
      createdAt: DateTime.now(),
    );
  }
}

// ============================================================================
// Payout - Pago al conductor
// ============================================================================

@freezed
class Payout with _$Payout {
  const factory Payout({
    required String id,
    required String driverId,
    required String orderId,
    required double amount,
    required String currency,
    required PayoutStatus status,
    @TimestampConverter() DateTime? processedAt,
    @TimestampConverter() required DateTime createdAt,
  }) = _Payout;

  factory Payout.fromJson(Map<String, dynamic> json) => _$PayoutFromJson(json);
}

enum PayoutStatus { pending, processed, failed }

// ============================================================================
// Notification - Notificación push
// ============================================================================

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, String>? data,
    @Default(false) bool read,
    @TimestampConverter() required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Crea una notificación con timestamp automático
  factory NotificationModel.create({
    required String id,
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, String>? data,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      read: false,
      createdAt: DateTime.now(),
    );
  }
}

// ============================================================================
// Converters
// ============================================================================

/// Convierte entre Timestamp de Firestore y DateTime
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json == null) {
      return DateTime.now();
    }
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is Map<String, dynamic>) {
      // Maneja formato {seconds: ..., nanoseconds: ...}
      final seconds = json['seconds'] as int? ?? 0;
      final nanoseconds = json['nanoseconds'] as int? ?? 0;
      return Timestamp(seconds: seconds, nanoseconds: nanoseconds).toDate();
    }
    if (json is DateTime) {
      return json;
    }
    // Fallback: intenta parsear como string ISO
    return DateTime.tryParse(json.toString()) ?? DateTime.now();
  }

  @override
  dynamic toJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}

/// Convierte entre GeoPoint de Firestore y nuestro GeoPoint
class FirestoreGeoPointConverter
    implements JsonConverter<GeoPoint, dynamic> {
  const FirestoreGeoPointConverter();

  @override
  GeoPoint fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return GeoPoint.fromJson(json);
    }
    throw Exception('Invalid GeoPoint format');
  }

  @override
  dynamic toJson(GeoPoint geoPoint) {
    return geoPoint.toJson();
  }
}
