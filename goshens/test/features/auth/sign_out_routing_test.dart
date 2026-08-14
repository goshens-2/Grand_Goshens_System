import 'package:flutter_test/flutter_test.dart';

String redirectAfterAuthChange({
  required bool isSignedIn,
  required String location,
}) {
  const publicLocations = {'/', '/sign-in', '/sign-up', '/reset-password'};
  if (!isSignedIn && !publicLocations.contains(location)) {
    return '/sign-in';
  }
  return location;
}

void main() {
  group('Sign out routing', () {
    test('admin dashboard redirects to sign-in after sign out', () {
      expect(
        redirectAfterAuthChange(isSignedIn: false, location: '/admin-dashboard'),
        '/sign-in',
      );
    });

    test('patient home redirects to sign-in after sign out', () {
      expect(
        redirectAfterAuthChange(isSignedIn: false, location: '/patient-home'),
        '/sign-in',
      );
    });

    test('sign-in stays public after sign out', () {
      expect(
        redirectAfterAuthChange(isSignedIn: false, location: '/sign-in'),
        '/sign-in',
      );
    });
  });
}
