import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? emergencyContact,
    String? allergiesOrNotes,
    String? avatarPath,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'address': address,
      'emergency_contact': emergencyContact,
      'allergies_or_notes': allergiesOrNotes,
      if (avatarPath != null) 'avatar_path': avatarPath,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    return await _supabase.from('profiles').select().eq('id', userId).single();
  }

  String? publicAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.trim().isEmpty) return null;
    if (avatarPath.startsWith('http')) return avatarPath;
    final url = _supabase.storage.from('avatars').getPublicUrl(avatarPath);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> uploadAvatar(Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final extension = contentType.contains('png')
        ? 'png'
        : contentType.contains('webp')
            ? 'webp'
            : 'jpg';
    final storagePath = '$userId/avatar.$extension';

    await _supabase.storage.from('avatars').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    await _supabase.from('profiles').update({
      'avatar_path': storagePath,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    return storagePath;
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(Supabase.instance.client);
}

final currentProfileProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});
