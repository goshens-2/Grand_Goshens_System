import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DeviceNotifications {
  DeviceNotifications._();
  static final DeviceNotifications instance = DeviceNotifications._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, macOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> show(String title, String body) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'goshens_alerts',
        'Goshens alerts',
        channelDescription: 'Appointment and comment updates from Goshens Dental Care',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(DateTime.now().millisecondsSinceEpoch % 100000, title, body, details);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
