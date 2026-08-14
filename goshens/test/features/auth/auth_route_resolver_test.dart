import 'package:flutter_test/flutter_test.dart';
import 'package:goshens/core/router/route_names.dart';
import 'package:goshens/features/auth/data/auth_route_resolver.dart';

void main() {
  group('Auth route resolver', () {
    test('admin role routes to admin dashboard', () {
      final decision = resolveRouteFromSessionData(
        role: 'admin',
        email: 'admin@goshens.com',
        fullName: null,
      );

      expect(decision.routeName, RouteNames.adminDashboard);
      expect(decision.shouldSignOut, false);
    });

    test('admin email without admin role is rejected', () {
      final decision = resolveRouteFromSessionData(
        role: 'patient',
        email: 'admin@goshens.com',
        fullName: 'Goshens Admin',
      );

      expect(decision.routeName, RouteNames.signIn);
      expect(decision.shouldSignOut, isTrue);
      expect(decision.errorMessage, isNotEmpty);
    });

    test('patient with incomplete profile routes to profile setup', () {
      final decision = resolveRouteFromSessionData(
        role: 'patient',
        email: 'patient@test.com',
        fullName: null,
      );

      expect(decision.routeName, RouteNames.patientProfileSetup);
    });
  });
}
