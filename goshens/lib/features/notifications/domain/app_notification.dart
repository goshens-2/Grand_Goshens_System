import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    @JsonKey(name: 'recipient_id') required String recipientId,
    required String type,
    required String title,
    required String body,
    @JsonKey(name: 'related_appointment_id') String? relatedAppointmentId,
    @JsonKey(name: 'related_prescription_id') String? relatedPrescriptionId,
    @JsonKey(name: 'related_conversation_id') String? relatedConversationId,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}
