import 'package:flutter_test/flutter_test.dart';
import 'package:goshens/core/router/route_extras.dart';
import 'package:goshens/core/router/route_names.dart';

void main() {
  group('Route extras', () {
    test('accepts Map<String, String> without throwing', () {
      final extra = asStringKeyedMap({'serviceId': 'abc', 'serviceName': 'Cleaning'});
      expect(extra?['serviceId'], 'abc');
      expect(extra?['serviceName'], 'Cleaning');
    });

    test('returns null for missing extra', () {
      expect(asStringKeyedMap(null), isNull);
    });

    test('reads nested names safely', () {
      expect(embeddedName({'full_name': 'Ada'}, 'Unknown'), 'Ada');
      expect(embeddedName(null), 'Unknown');
    });

    test('sanitizes PostgREST search needles', () {
      expect(sanitizeSearchNeedle('whitening, *'), 'whitening');
    });
  });

  group('Deployment routes', () {
    test('password recovery route exists', () {
      expect(RouteNames.resetPassword, 'reset_password');
    });
  });
}
