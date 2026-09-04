/// Clinic analytics built from appointments. A visit counts only after check-in
/// (QR scan or an admin confirming the patient arrived). Booked-but-not-seen
/// appointments never increment visit totals.
class ClinicVisit {
  const ClinicVisit({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.serviceName,
    required this.visitedAt,
    required this.status,
    this.phone,
    this.reference,
    this.qrCheckedIn = false,
    this.dentistNote,
    this.patientNote,
  });

  final String appointmentId;
  final String patientId;
  final String patientName;
  final String? phone;
  final String serviceName;
  final DateTime visitedAt;
  final String status;
  final String? reference;
  final bool qrCheckedIn;
  final String? dentistNote;
  final String? patientNote;

  String get checkInMethod => qrCheckedIn ? 'QR scan' : 'Confirmed check-in';
}

class PatientVisitSummary {
  const PatientVisitSummary({
    required this.patientId,
    required this.name,
    required this.visitCount,
    required this.visits,
    this.phone,
    this.email,
    this.lastVisitAt,
  });

  final String patientId;
  final String name;
  final String? phone;
  final String? email;
  final int visitCount;
  final DateTime? lastVisitAt;
  final List<ClinicVisit> visits;
}

class DayCount {
  const DayCount({required this.day, required this.count});

  final DateTime day;
  final int count;
}

class NamedCount {
  const NamedCount({required this.label, required this.count});

  final String label;
  final int count;
}

/// The analytics cards on the More/Analytics screen that drill down into a
/// grouped patient list. Each group only shows patients that belong to it.
enum AnalyticsGroup {
  enrolled,
  clinicVisits,
  pendingRequests,
  upcoming,
  noShows,
  cancelled,
  docRegistered,
}

class ClinicAnalyticsSnapshot {
  const ClinicAnalyticsSnapshot({
    required this.enrolledPatients,
    required this.totalVisits,
    required this.uniqueVisitors,
    required this.visitsToday,
    required this.pendingRequests,
    required this.upcomingScheduled,
    required this.noShows,
    required this.cancelled,
    required this.docRegisteredPatients,
    required this.visitsByService,
    required this.appointmentsByStatus,
    required this.visitsLast14Days,
    required this.patients,
    required this.groupedPatients,
  });

  final int enrolledPatients;
  final int totalVisits;
  final int uniqueVisitors;
  final int visitsToday;
  final int pendingRequests;
  final int upcomingScheduled;
  final int noShows;
  final int cancelled;
  final int docRegisteredPatients;
  final List<NamedCount> visitsByService;
  final List<NamedCount> appointmentsByStatus;
  final List<DayCount> visitsLast14Days;
  final List<PatientVisitSummary> patients;
  final Map<AnalyticsGroup, List<PatientVisitSummary>> groupedPatients;

  List<PatientVisitSummary> patientsFor(AnalyticsGroup group) => groupedPatients[group] ?? const [];
}

class ClinicAnalyticsCalculator {
  /// A visit is recorded when the patient actually arrived.
  static bool isClinicVisit(Map<String, dynamic> appointment) {
    return appointment['check_in_at'] != null;
  }

  static DateTime? parseTime(Object? value) {
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  static String _nestedName(Object? nested, String key, String fallback) {
    if (nested is Map) {
      final value = nested[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    if (nested is List && nested.isNotEmpty) {
      return _nestedName(nested.first, key, fallback);
    }
    return fallback;
  }

  static String? _nestedPhone(Object? nested) {
    if (nested is Map) return nested['phone']?.toString();
    if (nested is List && nested.isNotEmpty) return _nestedPhone(nested.first);
    return null;
  }

  static bool _qrUsed(Object? tokens) {
    if (tokens is Map) return tokens['used_at'] != null;
    if (tokens is List && tokens.isNotEmpty && tokens.first is Map) {
      return (tokens.first as Map)['used_at'] != null;
    }
    return false;
  }

  static ClinicVisit? visitFromAppointment(Map<String, dynamic> appointment) {
    if (!isClinicVisit(appointment)) return null;
    final patientId = appointment['patient_id']?.toString();
    if (patientId == null || patientId.isEmpty) return null;

    final visitedAt = parseTime(appointment['check_in_at']) ??
        parseTime(appointment['final_start_at']) ??
        parseTime(appointment['created_at']) ??
        DateTime.now();

    return ClinicVisit(
      appointmentId: appointment['id']?.toString() ?? patientId,
      patientId: patientId,
      patientName: _nestedName(appointment['profiles'], 'full_name', 'Patient'),
      phone: _nestedPhone(appointment['profiles']),
      serviceName: _nestedName(appointment['services'], 'name', 'Clinic visit'),
      visitedAt: visitedAt,
      status: appointment['status']?.toString() ?? 'checked_in',
      reference: appointment['appointment_reference']?.toString(),
      qrCheckedIn: _qrUsed(appointment['appointment_qr_tokens']),
      dentistNote: appointment['dentist_response']?.toString(),
      patientNote: appointment['patient_note']?.toString(),
    );
  }

  static ClinicAnalyticsSnapshot build({
    required List<Map<String, dynamic>> patients,
    required List<Map<String, dynamic>> appointments,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);

    final visits = appointments
        .map(visitFromAppointment)
        .whereType<ClinicVisit>()
        .toList()
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));

    final byPatient = <String, List<ClinicVisit>>{};
    for (final visit in visits) {
      byPatient.putIfAbsent(visit.patientId, () => []).add(visit);
    }

    final patientRows = patients.map((profile) {
      final id = profile['id']?.toString() ?? '';
      final patientVisits = byPatient[id] ?? const <ClinicVisit>[];
      return PatientVisitSummary(
        patientId: id,
        name: profile['full_name']?.toString() ?? 'Patient',
        phone: profile['phone']?.toString(),
        email: profile['email']?.toString(),
        visitCount: patientVisits.length,
        lastVisitAt: patientVisits.isEmpty ? null : patientVisits.first.visitedAt,
        visits: patientVisits,
      );
    }).toList()
      ..sort((a, b) {
        final byCount = b.visitCount.compareTo(a.visitCount);
        if (byCount != 0) return byCount;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    // Patients who visited but are missing from the profiles list still appear.
    for (final entry in byPatient.entries) {
      if (patientRows.any((row) => row.patientId == entry.key)) continue;
      final visitsForPatient = entry.value;
      patientRows.add(
        PatientVisitSummary(
          patientId: entry.key,
          name: visitsForPatient.first.patientName,
          phone: visitsForPatient.first.phone,
          visitCount: visitsForPatient.length,
          lastVisitAt: visitsForPatient.first.visitedAt,
          visits: visitsForPatient,
        ),
      );
    }

    final patientRowsById = <String, PatientVisitSummary>{
      for (final row in patientRows) row.patientId: row,
    };
    final profileById = <String, Map<String, dynamic>>{
      for (final profile in patients)
        if (profile['id'] != null) profile['id'].toString(): profile,
    };

    PatientVisitSummary summaryForAppointment(Map<String, dynamic> appointment) {
      final id = appointment['patient_id']?.toString() ?? '';
      final existing = patientRowsById[id];
      if (existing != null) return existing;
      return PatientVisitSummary(
        patientId: id,
        name: _nestedName(appointment['profiles'], 'full_name', 'Patient'),
        phone: _nestedPhone(appointment['profiles']),
        visitCount: 0,
        visits: const [],
      );
    }

    List<PatientVisitSummary> groupFromAppointments(Iterable<Map<String, dynamic>> rows) {
      final byId = <String, PatientVisitSummary>{};
      for (final row in rows) {
        final summary = summaryForAppointment(row);
        byId[summary.patientId] = summary;
      }
      final result = byId.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return result;
    }

    final serviceCounts = <String, int>{};
    for (final visit in visits) {
      serviceCounts[visit.serviceName] = (serviceCounts[visit.serviceName] ?? 0) + 1;
    }
    final serviceRows = serviceCounts.entries
        .map((e) => NamedCount(label: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final statusCounts = <String, int>{};
    for (final appointment in appointments) {
      final status = (appointment['status']?.toString() ?? 'unknown').replaceAll('_', ' ');
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    final statusRows = statusCounts.entries
        .map((e) => NamedCount(label: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final last14 = <DayCount>[];
    for (var i = 13; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final count = visits.where((visit) {
        final local = DateTime(visit.visitedAt.year, visit.visitedAt.month, visit.visitedAt.day);
        return local == day;
      }).length;
      last14.add(DayCount(day: day, count: count));
    }

    bool isPendingRow(Map<String, dynamic> row) => row['status'] == 'pending_review';
    bool isNoShowRow(Map<String, dynamic> row) => row['status'] == 'no_show';
    bool isCancelledRow(Map<String, dynamic> row) => row['status'] == 'cancelled' || row['status'] == 'rejected';

    final tomorrow = today.add(const Duration(days: 1));
    DateTime? appointmentDay(Map<String, dynamic> row) {
      final finalStart = parseTime(row['final_start_at']);
      if (finalStart != null) return DateTime(finalStart.year, finalStart.month, finalStart.day);
      final requested = row['requested_date']?.toString();
      if (requested != null && requested.isNotEmpty) {
        final parsed = DateTime.tryParse(requested);
        if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
      }
      return null;
    }

    bool isUpcomingTomorrowRow(Map<String, dynamic> row) {
      if (!{'approved', 'scheduled'}.contains(row['status'])) return false;
      final day = appointmentDay(row);
      return day == tomorrow;
    }

    final pendingRows = appointments.where(isPendingRow).toList();
    final upcomingRows = appointments.where(isUpcomingTomorrowRow).toList();
    final noShowRows = appointments.where(isNoShowRow).toList();
    final cancelledRows = appointments.where(isCancelledRow).toList();

    bool isEnrolledGoingForward(Map<String, dynamic> profile) {
      return (profile['registration_source']?.toString() ?? 'self') != 'legacy';
    }

    bool isDocRegistered(Map<String, dynamic> profile) {
      return profile['registration_source']?.toString() == 'doctor';
    }

    final enrolledPatientRows = patientRows
        .where((row) => isEnrolledGoingForward(profileById[row.patientId] ?? const {}))
        .toList();
    final docRegisteredRows = patientRows
        .where((row) => isDocRegistered(profileById[row.patientId] ?? const {}))
        .toList();
    final clinicVisitRows = patientRows.where((row) => row.visitCount > 0).toList();

    return ClinicAnalyticsSnapshot(
      enrolledPatients: enrolledPatientRows.length,
      totalVisits: visits.length,
      uniqueVisitors: byPatient.length,
      visitsToday: visits.where((visit) {
        final local = DateTime(visit.visitedAt.year, visit.visitedAt.month, visit.visitedAt.day);
        return local == today;
      }).length,
      pendingRequests: pendingRows.length,
      upcomingScheduled: upcomingRows.length,
      noShows: noShowRows.length,
      cancelled: cancelledRows.length,
      docRegisteredPatients: docRegisteredRows.length,
      visitsByService: serviceRows,
      appointmentsByStatus: statusRows,
      visitsLast14Days: last14,
      patients: patientRows,
      groupedPatients: {
        AnalyticsGroup.enrolled: enrolledPatientRows,
        AnalyticsGroup.clinicVisits: clinicVisitRows,
        AnalyticsGroup.pendingRequests: groupFromAppointments(pendingRows),
        AnalyticsGroup.upcoming: groupFromAppointments(upcomingRows),
        AnalyticsGroup.noShows: groupFromAppointments(noShowRows),
        AnalyticsGroup.cancelled: groupFromAppointments(cancelledRows),
        AnalyticsGroup.docRegistered: docRegisteredRows,
      },
    );
  }
}
