import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';

part 'patient_repository.g.dart';

/// Patients registered by the doctor/admin through the "add patient" flow
/// carry this registration source so they can be tracked separately in
/// analytics while still being fully searchable everywhere else.
const String doctorRegistrationSource = 'doctor';

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

  /// Creates a fully enrolled patient: an auth account the patient can sign
  /// in with later, plus their demographics saved on the profile. A second
  /// Supabase client is used so the admin's own session is left untouched.
  Future<String> createPatientWithCredentials({
    required String fullName,
    required int age,
    required String phone,
    required String gender,
    required String residence,
    required String email,
    required String emergencyNotes,
    required String password,
    String? allergiesOrNotes,
  }) async {
    final tempClient = SupabaseClient(EnvConfig.supabaseUrl, EnvConfig.supabaseAnonKey);
    try {
      final dateOfBirth = DateTime.now();
      final estimatedBirthYear = dateOfBirth.year - age;
      final response = await tempClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'gender': gender,
          'address': residence.trim(),
          'emergency_contact': emergencyNotes.trim(),
          'allergies_or_notes': (allergiesOrNotes ?? '').trim(),
          'registration_source': doctorRegistrationSource,
        },
      );

      final newUserId = response.user?.id;
      if (newUserId == null) {
        throw Exception('Could not create the patient login. Please try again.');
      }

      // Belt-and-braces: make sure the profile carries the data even if the
      // trigger payload could not be read for any reason.
      await _supabase.from('profiles').update({
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'gender': gender,
        'address': residence.trim(),
        'emergency_contact': emergencyNotes.trim(),
        'allergies_or_notes': (allergiesOrNotes ?? '').trim(),
        'email': email.trim(),
        'date_of_birth': '$estimatedBirthYear-01-01',
        'registration_source': doctorRegistrationSource,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', newUserId);

      return newUserId;
    } finally {
      await tempClient.dispose();
    }
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
