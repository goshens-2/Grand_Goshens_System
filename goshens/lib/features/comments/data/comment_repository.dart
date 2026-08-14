import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentRepository {
  final SupabaseClient _supabase;

  CommentRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getApprovedComments({int limit = 12}) async {
    final response = await _supabase
        .from('service_comments')
        .select('*, services(id, name)')
        .eq('status', 'approved')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCommentsForService(String serviceId) async {
    final userId = _supabase.auth.currentUser?.id;
    final response = await _supabase
        .from('service_comments')
        .select('*, services(id, name)')
        .eq('service_id', serviceId)
        .order('created_at', ascending: false);

    final comments = List<Map<String, dynamic>>.from(response);
    return comments.where((comment) {
      final status = comment['status'] as String? ?? '';
      return status == 'approved' || comment['patient_id'] == userId;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllComments() async {
    final response = await _supabase
        .from('service_comments')
        .select('*, services(id, name)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPendingComments() async {
    final response = await _supabase
        .from('service_comments')
        .select('*, services(id, name)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> submitComment({
    required String serviceId,
    required String body,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Please sign in to comment.');

    final text = body.trim();
    if (text.length < 8) {
      throw Exception('Please write a little more so the doctor can review your comment.');
    }

    await _supabase.from('service_comments').insert({
      'service_id': serviceId,
      'patient_id': userId,
      'body': text,
      'status': 'pending',
    });
  }

  Future<void> reviewComment({
    required String commentId,
    required String status,
  }) async {
    if (status != 'approved' && status != 'rejected') {
      throw Exception('Invalid comment status');
    }

    await _supabase.from('service_comments').update({
      'status': status,
      'reviewed_by': _supabase.auth.currentUser?.id,
      'reviewed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }
}

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(Supabase.instance.client);
});

final approvedHomeCommentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(commentRepositoryProvider).getApprovedComments();
});

final pendingCommentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(commentRepositoryProvider).getPendingComments();
});

final adminCommentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(commentRepositoryProvider).getAllComments();
});

final serviceCommentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, serviceId) {
  return ref.watch(commentRepositoryProvider).getCommentsForService(serviceId);
});
