import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'admin_availability_repository.g.dart';

class AdminAvailabilityRepository {
  final SupabaseClient _supabase;

  AdminAvailabilityRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getPeriods() async {
    final response = await _supabase
        .from('dentist_availability_periods')
        .select()
        .order('day_of_week')
        .order('start_time');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> togglePeriodActive(String id, bool isActive) async {
    await _supabase
        .from('dentist_availability_periods')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}

@riverpod
AdminAvailabilityRepository adminAvailabilityRepository(AdminAvailabilityRepositoryRef ref) {
  return AdminAvailabilityRepository(Supabase.instance.client);
}
