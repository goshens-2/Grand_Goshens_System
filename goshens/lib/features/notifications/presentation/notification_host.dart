import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../data/device_notifications.dart';
import '../data/notification_repository.dart';

class NotificationHost extends ConsumerStatefulWidget {
  const NotificationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends ConsumerState<NotificationHost> {
  final Set<String> _seenIds = <String>{};
  var _primed = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    DeviceNotifications.instance.initialize();
  }

  void _resetForUser(String? userId) {
    _userId = userId;
    _primed = false;
    _seenIds.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateChangesProvider, (previous, next) {
      final userId = next.valueOrNull?.session?.user.id ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId != _userId) {
        _resetForUser(userId);
        DeviceNotifications.instance.cancelAll();
        ref.invalidate(userNotificationsProvider);
      }
    });

    ref.listen(userNotificationsProvider, (previous, next) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        _resetForUser(null);
        return;
      }
      if (_userId != currentUserId) {
        _resetForUser(currentUserId);
      }

      final items = (next.valueOrNull ?? []).where((item) => item.recipientId == currentUserId).toList();
      if (!_primed) {
        _seenIds
          ..clear()
          ..addAll(items.map((notification) => notification.id));
        _primed = true;
        return;
      }

      for (final notification in items) {
        if (_seenIds.add(notification.id)) {
          DeviceNotifications.instance.show(notification.title, notification.body);
        }
      }
    });

    return widget.child;
  }
}
