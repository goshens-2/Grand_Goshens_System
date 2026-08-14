import 'package:flutter_test/flutter_test.dart';

// Helper class simulating appointment scheduling & status transitions logic
class AppointmentManager {
  final List<Map<String, dynamic>> _appointments = [];

  List<Map<String, dynamic>> get appointments => List.unmodifiable(_appointments);

  Map<String, dynamic> createBookingRequest({
    required String patientId,
    required String serviceId,
    required String requestedDate,
    required String preferredPeriod,
    String? patientNote,
  }) {
    final appointment = {
      'id': 'appt-${_appointments.length + 1}',
      'patient_id': patientId,
      'service_id': serviceId,
      'requested_date': requestedDate,
      'preferred_period': preferredPeriod,
      'patient_note': patientNote,
      'status': 'pending_review',
      'created_at': DateTime.now().toIso8601String(),
    };
    _appointments.add(appointment);
    return appointment;
  }

  bool checkScheduleConflict({
    required DateTime startAt,
    required DateTime endAt,
  }) {
    for (final appt in _appointments) {
      if (appt['status'] == 'scheduled' || appt['status'] == 'approved') {
        if (appt['final_start_at'] != null && appt['final_end_at'] != null) {
          final existingStart = DateTime.parse(appt['final_start_at']);
          final existingEnd = DateTime.parse(appt['final_end_at']);

          // Overlap condition
          if (startAt.isBefore(existingEnd) && endAt.isAfter(existingStart)) {
            return true; // Conflict exists
          }
        }
      }
    }
    return false;
  }

  Map<String, dynamic> scheduleAppointment({
    required String appointmentId,
    required DateTime finalStartAt,
    required DateTime finalEndAt,
  }) {
    final index = _appointments.indexWhere((a) => a['id'] == appointmentId);
    if (index == -1) throw ArgumentError('Appointment not found');

    if (checkScheduleConflict(startAt: finalStartAt, endAt: finalEndAt)) {
      throw StateError('Scheduling conflict detected for the selected slot.');
    }

    final updated = Map<String, dynamic>.from(_appointments[index]);
    updated['status'] = 'scheduled';
    updated['final_start_at'] = finalStartAt.toIso8601String();
    updated['final_end_at'] = finalEndAt.toIso8601String();
    updated['qr_token'] = generateSecureQrToken(appointmentId);
    updated['notification_sent'] = true;
    _appointments[index] = updated;

    return updated;
  }

  Map<String, dynamic> updateStatus(String appointmentId, String newStatus) {
    final validStatuses = [
      'pending_review',
      'approved',
      'scheduled',
      'checked_in',
      'in_consultation',
      'completed',
      'rejected',
      'cancelled',
      'no_show',
    ];

    if (!validStatuses.contains(newStatus)) {
      throw ArgumentError('Invalid status: $newStatus');
    }

    final index = _appointments.indexWhere((a) => a['id'] == appointmentId);
    if (index == -1) throw ArgumentError('Appointment not found');

    final updated = Map<String, dynamic>.from(_appointments[index]);
    updated['status'] = newStatus;
    _appointments[index] = updated;

    return updated;
  }

  String generateSecureQrToken(String appointmentId) {
    // Generate opaque token (does not contain PII like name, phone, or raw user ID)
    final token = 'TOKEN-$appointmentId-${DateTime.now().millisecondsSinceEpoch}';
    return token;
  }

  bool validateQrToken(String token, String expectedAppointmentId) {
    return token.contains('TOKEN-$expectedAppointmentId-');
  }
}

void main() {
  group('Booking & Appointment Logic Tests', () {
    late AppointmentManager manager;

    setUp(() {
      manager = AppointmentManager();
    });

    test('Create booking request defaults to pending_review status', () {
      final appt = manager.createBookingRequest(
        patientId: 'patient-1',
        serviceId: 'service-cleaning',
        requestedDate: '2026-08-10',
        preferredPeriod: 'Morning',
        patientNote: 'Regular checkup',
      );

      expect(appt['status'], 'pending_review');
      expect(appt['patient_id'], 'patient-1');
      expect(appt['preferred_period'], 'Morning');
    });

    test('Scheduling an appointment sets exact date/time and updates status', () {
      final appt = manager.createBookingRequest(
        patientId: 'patient-1',
        serviceId: 'service-cleaning',
        requestedDate: '2026-08-10',
        preferredPeriod: 'Morning',
      );

      final start = DateTime(2026, 8, 10, 9, 30);
      final end = DateTime(2026, 8, 10, 10, 00);

      final scheduled = manager.scheduleAppointment(
        appointmentId: appt['id'],
        finalStartAt: start,
        finalEndAt: end,
      );

      expect(scheduled['status'], 'scheduled');
      expect(scheduled['final_start_at'], start.toIso8601String());
      expect(scheduled['qr_token'], isNotNull);
      expect(scheduled['notification_sent'], isTrue);
    });

    test('Conflict detection prevents overlapping appointments', () {
      final appt1 = manager.createBookingRequest(
        patientId: 'patient-1',
        serviceId: 'service-1',
        requestedDate: '2026-08-10',
        preferredPeriod: 'Morning',
      );

      final start1 = DateTime(2026, 8, 10, 9, 0);
      final end1 = DateTime(2026, 8, 10, 10, 0);

      manager.scheduleAppointment(
        appointmentId: appt1['id'],
        finalStartAt: start1,
        finalEndAt: end1,
      );

      final appt2 = manager.createBookingRequest(
        patientId: 'patient-2',
        serviceId: 'service-2',
        requestedDate: '2026-08-10',
        preferredPeriod: 'Morning',
      );

      // Overlapping slot: 9:30 to 10:30
      final start2 = DateTime(2026, 8, 10, 9, 30);
      final end2 = DateTime(2026, 8, 10, 10, 30);

      expect(
        () => manager.scheduleAppointment(
          appointmentId: appt2['id'],
          finalStartAt: start2,
          finalEndAt: end2,
        ),
        throwsStateError,
      );
    });

    test('Status transitions work through full clinical lifecycle', () {
      final appt = manager.createBookingRequest(
        patientId: 'patient-1',
        serviceId: 'service-1',
        requestedDate: '2026-08-10',
        preferredPeriod: 'Morning',
      );

      var updated = manager.updateStatus(appt['id'], 'approved');
      expect(updated['status'], 'approved');

      updated = manager.updateStatus(appt['id'], 'checked_in');
      expect(updated['status'], 'checked_in');

      updated = manager.updateStatus(appt['id'], 'in_consultation');
      expect(updated['status'], 'in_consultation');

      updated = manager.updateStatus(appt['id'], 'completed');
      expect(updated['status'], 'completed');
    });

    test('Secure QR Token generation does not leak PII', () {
      final token = manager.generateSecureQrToken('appt-1');

      expect(token.contains('patient-1'), false);
      expect(token.contains('Sarah'), false);
      expect(token.contains('+256'), false);
      expect(manager.validateQrToken(token, 'appt-1'), true);
    });
  });
}
