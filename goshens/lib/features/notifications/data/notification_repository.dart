import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/app_notification.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .where((json) => json['recipient_id']?.toString() == userId)
              .map(AppNotification.fromJson)
              .toList();
        });
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    try {
      await _supabase.rpc('mark_all_notifications_read');
    } catch (_) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('notifications').update({'is_read': true}).eq('recipient_id', userId).eq('is_read', false);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.rpc('delete_notification', params: {'p_id': notificationId});
    } catch (_) {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    }
  }

  Future<void> clearAll() async {
    try {
      await _supabase.rpc('clear_all_notifications');
    } catch (_) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('notifications').delete().eq('recipient_id', userId);
    }
  }

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? relatedAppointmentId,
    String? relatedPrescriptionId,
    String? relatedConversationId,
  }) async {
    await _supabase.from('notifications').insert({
      'recipient_id': recipientId,
      'type': type,
      'title': title,
      'body': body,
      if (relatedAppointmentId case final id?) 'related_appointment_id': id,
      if (relatedPrescriptionId case final id?) 'related_prescription_id': id,
      if (relatedConversationId case final id?) 'related_conversation_id': id,
    });
  }
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) {
  return NotificationRepository(Supabase.instance.client);
}

@riverpod
Stream<List<AppNotification>> userNotifications(UserNotificationsRef ref) {
  ref.watch(authStateChangesProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchUserNotifications(userId);
}

@riverpod
int unreadNotificationCount(UnreadNotificationCountRef ref) {
  final notifications = ref.watch(userNotificationsProvider).valueOrNull ?? [];
  final userId = Supabase.instance.client.auth.currentUser?.id;
  return notifications.where((n) => !n.isRead && (userId == null || n.recipientId == userId)).length;
}
