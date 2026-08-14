import 'dart:html' as html;

class DeviceNotifications {
  DeviceNotifications._();
  static final DeviceNotifications instance = DeviceNotifications._();

  Future<void> initialize() async {
    try {
      if (html.Notification.permission != 'granted') {
        await html.Notification.requestPermission();
      }
    } catch (_) {
      // Browser may block permission prompts until a user gesture.
    }
  }

  Future<void> show(String title, String body) async {
    try {
      if (html.Notification.permission != 'granted') {
        final permission = await html.Notification.requestPermission();
        if (permission != 'granted') return;
      }
      html.Notification(title, body: body);
    } catch (_) {
      // Ignore if the browser cannot show a system notification.
    }
  }

  Future<void> cancelAll() async {}
}
