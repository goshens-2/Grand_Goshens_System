import 'package:flutter_test/flutter_test.dart';
import 'package:goshens/core/router/route_names.dart';
import 'package:goshens/features/patient/presentation/clinic_information_screen.dart';

void main() {
  group('Clinic hours formatting', () {
    test('formats a working-hours map', () {
      expect(
        formatClinicHours({
          'Monday - Friday': '9:00 AM - 5:00 PM',
          'Saturday': '9:00 AM - 1:00 PM',
        }),
        'Monday - Friday: 9:00 AM - 5:00 PM\nSaturday: 9:00 AM - 1:00 PM',
      );
    });

    test('falls back when hours are missing', () {
      expect(
        formatClinicHours(null),
        'Please call the clinic for working hours.',
      );
    });
  });

  group('Account and clinic routes', () {
    test('account settings and clinic information route names are defined', () {
      expect(RouteNames.accountSettings, 'account_settings');
      expect(RouteNames.clinicInformation, 'clinic_information');
      expect(RouteNames.patientProfileSetup, 'patient_profile_setup');
    });
  });
}
