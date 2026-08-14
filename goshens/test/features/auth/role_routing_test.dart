import 'package:flutter_test/flutter_test.dart';

String determineInitialRoute({
  required bool isSignedIn,
  required String? protectedRole,
  required bool isProfileComplete,
}) {
  if (!isSignedIn) {
    return '/sign-in';
  }

  if (protectedRole == 'admin') {
    return '/admin-dashboard';
  }

  if (!isProfileComplete) {
    return '/patient-profile-setup';
  }

  return '/patient-home';
}

void main() {
  group('Role-Based Routing Tests', () {
    test('Unauthenticated user routes to sign-in', () {
      final route = determineInitialRoute(
        isSignedIn: false,
        protectedRole: null,
        isProfileComplete: false,
      );
      expect(route, '/sign-in');
    });

    test('protected admin role routes directly to admin dashboard', () {
      final route = determineInitialRoute(
        isSignedIn: true,
        protectedRole: 'admin',
        isProfileComplete: true,
      );
      expect(route, '/admin-dashboard');
    });

    test('Patient with incomplete profile routes to profile setup', () {
      final route = determineInitialRoute(
        isSignedIn: true,
        protectedRole: 'patient',
        isProfileComplete: false,
      );
      expect(route, '/patient-profile-setup');
    });

    test('Patient with complete profile routes to patient home', () {
      final route = determineInitialRoute(
        isSignedIn: true,
        protectedRole: 'patient',
        isProfileComplete: true,
      );
      expect(route, '/patient-home');
    });

    test('patient role cannot route to the admin dashboard', () {
      final route = determineInitialRoute(
        isSignedIn: true,
        protectedRole: 'patient',
        isProfileComplete: true,
      );
      expect(route, '/patient-home');
      expect(route, isNot('/admin-dashboard'));
    });
  });
}
