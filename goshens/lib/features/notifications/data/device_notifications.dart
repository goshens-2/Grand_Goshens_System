export 'device_notifications_stub.dart'
    if (dart.library.html) 'device_notifications_web.dart'
    if (dart.library.io) 'device_notifications_io.dart';
