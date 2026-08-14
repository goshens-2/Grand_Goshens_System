import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'clinic_repository.g.dart';

class ClinicRepository {
  final SupabaseClient _supabase;

  ClinicRepository(this._supabase);

  Future<Map<String, dynamic>?> getClinicSettings() async {
    try {
      return await _supabase.from('clinic_settings').select().maybeSingle();
    } catch (e) {
      return null;
    }
  }
}

@riverpod
ClinicRepository clinicRepository(ClinicRepositoryRef ref) {
  return ClinicRepository(Supabase.instance.client);
}

@riverpod
Future<Map<String, dynamic>?> clinicSettings(ClinicSettingsRef ref) {
  return ref.watch(clinicRepositoryProvider).getClinicSettings();
}
