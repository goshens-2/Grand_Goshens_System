class DeviceNotifications {
  DeviceNotifications._();
  static final DeviceNotifications instance = DeviceNotifications._();

  Future<void> initialize() async {}

  Future<void> show(String title, String body) async {}

  Future<void> cancelAll() async {}
}
