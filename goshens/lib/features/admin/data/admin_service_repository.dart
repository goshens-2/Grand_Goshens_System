import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'admin_service_repository.g.dart';

class AdminServiceRepository {
  final SupabaseClient _supabase;

  AdminServiceRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getAllServices() async {
    final response = await _supabase
        .from('services')
        .select()
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> addService({
    required String name,
    required String description,
    required int duration,
    required bool isPublished,
    String iconName = 'medical_services',
    List<String> imagePaths = const [],
  }) async {
    final row = await _supabase.from('services').insert({
      'name': name,
      'description': description,
      'estimated_duration_minutes': duration,
      'is_published': isPublished,
      'icon_name': iconName,
      'image_paths': imagePaths,
      if (imagePaths.isNotEmpty) 'image_path': imagePaths.first,
    }).select('id').single();

    return row['id'] as String;
  }

  Future<void> updateService({
    required String id,
    required String name,
    required String description,
    required int duration,
    required bool isPublished,
    String iconName = 'medical_services',
    List<String>? imagePaths,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      'description': description,
      'estimated_duration_minutes': duration,
      'is_published': isPublished,
      'icon_name': iconName,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (imagePaths != null) {
      updates['image_paths'] = imagePaths;
      updates['image_path'] = imagePaths.isEmpty ? null : imagePaths.first;
    }

    await _supabase.from('services').update(updates).eq('id', id);
  }

  Future<String> uploadServiceImage({
    required String serviceId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final extension = contentType.contains('png')
        ? 'png'
        : contentType.contains('webp')
            ? 'webp'
            : 'jpg';
    final storagePath = '$serviceId/${const Uuid().v4()}.$extension';

    await _supabase.storage.from('service-images').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    return storagePath;
  }

  String? publicImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    return _supabase.storage.from('service-images').getPublicUrl(path);
  }
}

@riverpod
AdminServiceRepository adminServiceRepository(AdminServiceRepositoryRef ref) {
  return AdminServiceRepository(Supabase.instance.client);
}
