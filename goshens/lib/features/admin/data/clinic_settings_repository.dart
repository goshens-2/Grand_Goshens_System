import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'clinic_settings_repository.g.dart';

class ClinicSettingsRepository {
  final SupabaseClient _supabase;

  ClinicSettingsRepository(this._supabase);

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _supabase.from('clinic_settings').select().limit(1).single();
    return response;
  }

  Future<void> updateSettings(String id, Map<String, dynamic> updates) async {
    await _supabase.from('clinic_settings').update(updates).eq('id', id);
  }
}

@riverpod
ClinicSettingsRepository clinicSettingsRepository(ClinicSettingsRepositoryRef ref) {
  return ClinicSettingsRepository(Supabase.instance.client);
}
