import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'availability_repository.g.dart';

class AvailabilityRepository {
  final SupabaseClient _supabase;

  AvailabilityRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getActivePeriods() async {
    final response = await _supabase
        .from('dentist_availability_periods')
        .select()
        .eq('is_active', true)
        .order('day_of_week')
        .order('start_time');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getExceptions() async {
    final response = await _supabase.from('availability_exceptions').select();
    return List<Map<String, dynamic>>.from(response);
  }
}

@riverpod
AvailabilityRepository availabilityRepository(AvailabilityRepositoryRef ref) {
  return AvailabilityRepository(Supabase.instance.client);
}

@riverpod
Future<List<Map<String, dynamic>>> activePeriods(ActivePeriodsRef ref) {
  return ref.watch(availabilityRepositoryProvider).getActivePeriods();
}
