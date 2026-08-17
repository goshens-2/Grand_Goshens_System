import 'package:flutter_test/flutter_test.dart';

import 'package:goshens/features/admin/data/clinic_analytics.dart';

void main() {
  group('ClinicAnalyticsCalculator', () {
    test('counts a visit only when check_in_at is set', () {
      final snapshot = ClinicAnalyticsCalculator.build(
        now: DateTime(2026, 8, 17, 15),
        patients: [
          {'id': 'p1', 'full_name': 'Ada', 'phone': '0700'},
          {'id': 'p2', 'full_name': 'Ben', 'phone': '0701'},
        ],
        appointments: [
          {
            'id': 'a1',
            'patient_id': 'p1',
            'status': 'scheduled',
            'profiles': {'full_name': 'Ada', 'phone': '0700'},
            'services': {'name': 'Cleaning'},
          },
          {
            'id': 'a2',
            'patient_id': 'p1',
            'status': 'checked_in',
            'check_in_at': '2026-08-17T10:30:00Z',
            'appointment_reference': 'ABC123',
            'profiles': {'full_name': 'Ada', 'phone': '0700'},
            'services': {'name': 'Cleaning'},
            'appointment_qr_tokens': {'used_at': '2026-08-17T10:30:00Z'},
          },
          {
            'id': 'a3',
            'patient_id': 'p1',
            'status': 'completed',
            'check_in_at': '2026-08-10T08:00:00Z',
            'profiles': {'full_name': 'Ada'},
            'services': {'name': 'Extraction'},
          },
          {
            'id': 'a4',
            'patient_id': 'p2',
            'status': 'cancelled',
            'profiles': {'full_name': 'Ben'},
            'services': {'name': 'Cleaning'},
          },
        ],
      );

      expect(snapshot.enrolledPatients, 2);
      expect(snapshot.totalVisits, 2);
      expect(snapshot.uniqueVisitors, 1);
      expect(snapshot.visitsToday, 1);
      expect(snapshot.upcomingScheduled, 1);
      expect(snapshot.cancelled, 1);

      final ada = snapshot.patients.firstWhere((row) => row.patientId == 'p1');
      expect(ada.visitCount, 2);
      expect(ada.visits.first.serviceName, 'Cleaning');
      expect(ada.visits.first.qrCheckedIn, isTrue);
      expect(ada.visits.first.checkInMethod, 'QR scan');
      expect(ada.visits.last.serviceName, 'Extraction');

      final ben = snapshot.patients.firstWhere((row) => row.patientId == 'p2');
      expect(ben.visitCount, 0);

      expect(snapshot.visitsByService.map((row) => row.label), ['Cleaning', 'Extraction']);
      expect(snapshot.visitsByService.first.count, 1);
    });

    test('ignores completed appointments that never checked in', () {
      expect(
        ClinicAnalyticsCalculator.isClinicVisit({
          'status': 'completed',
          'check_in_at': null,
        }),
        isFalse,
      );
      expect(
        ClinicAnalyticsCalculator.isClinicVisit({
          'status': 'checked_in',
          'check_in_at': '2026-08-17T10:00:00Z',
        }),
        isTrue,
      );
    });
  });
}
