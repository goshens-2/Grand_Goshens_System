import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/route_extras.dart';

part 'service_repository.g.dart';

class ServiceRepository {
  final SupabaseClient _supabase;

  ServiceRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getPublishedServices({String? query}) async {
    final needle = sanitizeSearchNeedle(query ?? '');
    final filter = _supabase.from('services').select().eq('is_published', true);
    final response = needle.isEmpty
        ? await filter.order('sort_order', ascending: true)
        : await filter
            .or('name.ilike.%$needle%,description.ilike.%$needle%')
            .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getServiceById(String id) async {
    return await _supabase.from('services').select().eq('id', id).maybeSingle();
  }

  String? publicImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    return _supabase.storage.from('service-images').getPublicUrl(path);
  }
}

@riverpod
ServiceRepository serviceRepository(ServiceRepositoryRef ref) {
  return ServiceRepository(Supabase.instance.client);
}

@riverpod
Future<List<Map<String, dynamic>>> publishedServices(PublishedServicesRef ref) {
  return ref.watch(serviceRepositoryProvider).getPublishedServices();
}

final serviceByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) {
  return ref.watch(serviceRepositoryProvider).getServiceById(id);
});

