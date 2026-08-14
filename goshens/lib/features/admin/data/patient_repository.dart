import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'patient_repository.g.dart';

class PatientRepository {
  final SupabaseClient _supabase;

  PatientRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getPatients() async {
    final adminRoles = await _supabase.from('user_roles').select('user_id').eq('role', 'admin');
    final adminIds = List<Map<String, dynamic>>.from(adminRoles)
        .map((row) => row['user_id'] as String?)
        .whereType<String>()
        .toSet();

    final response = await _supabase
        .from('profiles')
        .select('*')
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(response)
        .where((profile) => !adminIds.contains(profile['id']))
        .toList();
  }

  Future<Map<String, dynamic>> getPatientDetails(String patientId) async {
    final profileResponse = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', patientId)
        .single();
        
    final appointmentsResponse = await _supabase
        .from('appointments')
        .select('*, services(name)')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    final prescriptionsResponse = await _supabase
        .from('prescriptions')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return {
      'profile': profileResponse,
      'appointments': appointmentsResponse,
      'prescriptions': prescriptionsResponse,
    };
  }
}

@riverpod
PatientRepository patientRepository(PatientRepositoryRef ref) {
  return PatientRepository(Supabase.instance.client);
}
