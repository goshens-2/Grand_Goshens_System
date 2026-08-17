import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'clinic_analytics.dart';
import 'patient_repository.dart';

part 'clinic_analytics_repository.g.dart';

class ClinicAnalyticsRepository {
  ClinicAnalyticsRepository(this._supabase, this._patients);

  final SupabaseClient _supabase;
  final PatientRepository _patients;

  Future<ClinicAnalyticsSnapshot> loadSnapshot() async {
    final patients = await _patients.getPatients();
    List<Map<String, dynamic>> appointments;
    try {
      final response = await _supabase
          .from('appointments')
          .select(
            '*, profiles!appointments_patient_id_fkey(full_name, phone), services(name), appointment_qr_tokens(used_at)',
          )
          .order('created_at', ascending: false);
      appointments = List<Map<String, dynamic>>.from(response);
    } catch (_) {
      final response = await _supabase
          .from('appointments')
          .select(
            '*, profiles!appointments_patient_id_fkey(full_name, phone), services(name)',
          )
          .order('created_at', ascending: false);
      appointments = List<Map<String, dynamic>>.from(response);
    }

    return ClinicAnalyticsCalculator.build(
      patients: patients,
      appointments: appointments,
    );
  }
}

@riverpod
ClinicAnalyticsRepository clinicAnalyticsRepository(ClinicAnalyticsRepositoryRef ref) {
  return ClinicAnalyticsRepository(
    Supabase.instance.client,
    ref.watch(patientRepositoryProvider),
  );
}
