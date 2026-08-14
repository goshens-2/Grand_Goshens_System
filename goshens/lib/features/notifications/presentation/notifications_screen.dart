import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../auth/data/auth_session_cache.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  var _query = '';
  var _busy = false;

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(userNotificationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update notifications.\n$error'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This removes every notification for your account only. Other patients are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => ref.read(notificationRepositoryProvider).clearAll(), 'All notifications cleared.');
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _busy
                ? null
                : () => _run(
                      () => ref.read(notificationRepositoryProvider).markAllAsRead(),
                      'All notifications marked as read.',
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: _busy ? null : _clearAll,
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          final mine = notifications.where((item) => userId != null && item.recipientId == userId).toList();
          final visible = mine.where((item) {
            return matchesQuery(_query, [item.title, item.body, item.type]);
          }).toList();

          return Column(
            children: [
              ListSearchBar(
                hint: 'Search notifications',
                onChanged: (value) => setState(() => _query = value),
              ),
              if (_busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: visible.isEmpty
                    ? EmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: mine.isEmpty ? 'No notifications yet' : 'No matching notifications',
                        message: mine.isEmpty
                            ? 'Appointment updates, chat and prescriptions will land here.'
                            : 'Try a different search.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notification = visible[index];
                          return Dismissible(
                            key: ValueKey(notification.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              await ref.read(notificationRepositoryProvider).deleteNotification(notification.id);
                              ref.invalidate(userNotificationsProvider);
                              return true;
                            },
                            child: Material(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(color: scheme.outline),
                                ),
                                onTap: () => _open(notification),
                                trailing: IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _run(
                                    () => ref.read(notificationRepositoryProvider).deleteNotification(notification.id),
                                    'Notification cleared.',
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: notification.isRead
                                      ? scheme.surfaceContainerHighest
                                      : AppColors.primary.withValues(alpha: 0.12),
                                  child: Icon(
                                    _iconForType(notification.type),
                                    color: notification.isRead ? scheme.onSurfaceVariant : AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(notification.body),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt.toLocal()),
                                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _open(AppNotification notification) async {
    if (!notification.isRead) {
      await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
      ref.invalidate(userNotificationsProvider);
    }
    if (!mounted) return;
    if (notification.relatedAppointmentId != null) {
      final appointment = await Supabase.instance.client
          .from('appointments')
          .select('*, services(name)')
          .eq('id', notification.relatedAppointmentId!)
          .maybeSingle();
      if (!mounted) return;
      if (appointment != null &&
          (appointment['status'] == 'scheduled' || appointment['status'] == 'approved')) {
        context.pushNamed(RouteNames.patientAppointmentCard, extra: appointment);
        return;
      }
      context.pushNamed(RouteNames.patientBookings);
      return;
    }
    if (notification.type == 'comment_submitted' || notification.type == 'new_booking') {
      if (notification.type == 'comment_submitted') {
        context.pushNamed(AuthSessionCache.isAdmin ? RouteNames.adminComments : RouteNames.patientServices);
      } else {
        context.pushNamed(AuthSessionCache.isAdmin ? RouteNames.adminAppointments : RouteNames.patientBookings);
      }
      return;
    }
    if (notification.type == 'comment_approved' || notification.type == 'comment_rejected') {
      context.pushNamed(RouteNames.patientServices);
      return;
    }
    if (notification.type == 'prescription_ready' || notification.type == 'prescription') {
      context.pushNamed(RouteNames.patientPrescriptions);
      return;
    }
    if (notification.type == 'new_message') {
      if (notification.relatedConversationId != null) {
        context.pushNamed(
          RouteNames.patientChat,
          extra: <String, dynamic>{'conversationId': notification.relatedConversationId},
        );
      } else {
        context.pushNamed(AuthSessionCache.isAdmin ? RouteNames.adminChats : RouteNames.patientChat);
      }
      return;
    }
    context.pushNamed(RouteNames.patientBookings);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'appointment_update':
      case 'appointment_confirmed':
      case 'new_booking':
        return Icons.calendar_month;
      case 'prescription':
      case 'prescription_ready':
        return Icons.medication;
      case 'new_message':
        return Icons.message;
      case 'comment_submitted':
      case 'comment_approved':
      case 'comment_rejected':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications;
    }
  }
}
