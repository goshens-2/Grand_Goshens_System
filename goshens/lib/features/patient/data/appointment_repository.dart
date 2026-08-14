import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'appointment_repository.g.dart';

class AppointmentRepository {
  final SupabaseClient _supabase;

  AppointmentRepository(this._supabase);

  Future<Map<String, dynamic>?> getUpcomingAppointment() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final scheduled = await _supabase
          .from('appointments')
          .select('*, services(name, image_path)')
          .eq('patient_id', userId)
          .inFilter('status', ['scheduled', 'approved'])
          .gte('final_start_at', nowIso)
          .order('final_start_at', ascending: true)
          .limit(1)
          .maybeSingle();
      if (scheduled != null) return scheduled;

      return await _supabase
          .from('appointments')
          .select('*, services(name, image_path)')
          .eq('patient_id', userId)
          .eq('status', 'pending_review')
          .order('requested_date', ascending: true)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPatientAppointments() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('appointments')
        .select('*, services(name)')
        .eq('patient_id', userId)
        .order('requested_date', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> requestAppointment({
    required String serviceId,
    required String requestedDate,
    required String preferredPeriod,
    String? patientNote,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('appointments').insert({
      'patient_id': userId,
      'service_id': serviceId,
      'requested_date': requestedDate,
      'preferred_period': preferredPeriod,
      'patient_note': patientNote,
      'status': 'pending_review',
    });
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _supabase.from('appointments').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', appointmentId);
  }
}

@riverpod
AppointmentRepository appointmentRepository(AppointmentRepositoryRef ref) {
  return AppointmentRepository(Supabase.instance.client);
}

@riverpod
Future<Map<String, dynamic>?> upcomingAppointment(UpcomingAppointmentRef ref) {
  return ref.watch(appointmentRepositoryProvider).getUpcomingAppointment();
}
