// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      relatedAppointmentId: json['related_appointment_id'] as String?,
      relatedPrescriptionId: json['related_prescription_id'] as String?,
      relatedConversationId: json['related_conversation_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipient_id': instance.recipientId,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'related_appointment_id': instance.relatedAppointmentId,
      'related_prescription_id': instance.relatedPrescriptionId,
      'related_conversation_id': instance.relatedConversationId,
      'is_read': instance.isRead,
      'created_at': instance.createdAt.toIso8601String(),
    };
