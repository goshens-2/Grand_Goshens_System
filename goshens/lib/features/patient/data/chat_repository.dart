import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'chat_repository.g.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>> getOrCreatePatientConversation({String? patientId}) async {
    final userId = patientId ?? currentUserId;
    if (userId == null) throw Exception('Not signed in');

    final existing = await _supabase
        .from('conversations')
        .select()
        .eq('patient_id', userId)
        .maybeSingle();
    if (existing != null) return existing;

    return await _supabase
        .from('conversations')
        .insert({'patient_id': userId})
        .select()
        .single();
  }

  Future<Map<String, dynamic>?> getPatientConversation() async {
    final userId = currentUserId;
    if (userId == null) return null;
    try {
      return await getOrCreatePatientConversation(patientId: userId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getInbox() async {
    final response = await _supabase
        .from('conversations')
        .select('*, profiles!conversations_patient_id_fkey(id, full_name, avatar_path)')
        .order('updated_at', ascending: false);
    final conversations = List<Map<String, dynamic>>.from(response);
    final unread = await _unreadCounts();
    return conversations.map((conversation) {
      return {
        ...conversation,
        'unread_count': unread[conversation['id'] as String] ?? 0,
      };
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> watchInbox() async* {
    yield await getInbox();
    await for (final _ in _supabase.from('conversations').stream(primaryKey: ['id'])) {
      yield await getInbox();
    }
  }

  Future<Map<String, int>> _unreadCounts() async {
    final userId = currentUserId;
    if (userId == null) return {};
    final rows = await _supabase
        .from('messages')
        .select('conversation_id')
        .eq('is_read', false)
        .neq('sender_id', userId);
    final counts = <String, int>{};
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      final id = row['conversation_id'] as String?;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  Future<int> unreadCountForCurrentUser() async {
    final counts = await _unreadCounts();
    return counts.values.fold<int>(0, (sum, value) => sum + value);
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  Future<void> markConversationRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _supabase.rpc(
        'mark_conversation_read',
        params: {'p_conversation_id': conversationId},
      );
    } catch (_) {
      await _supabase
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
            'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    }
  }

  Future<void> sendText({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;
    await _insertMessage(
      conversationId: conversationId,
      messageType: 'text',
      content: text,
      replyToId: replyToId,
    );
  }

  Future<void> sendMedia({
    required String conversationId,
    required String messageType,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'application/octet-stream',
    String? caption,
    String? replyToId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');

    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'bin';
    final storagePath = '$conversationId/${const Uuid().v4()}.$extension';

    await _supabase.storage.from('chat-media').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    await _insertMessage(
      conversationId: conversationId,
      messageType: messageType,
      content: caption?.trim() ?? '',
      mediaPath: storagePath,
      mediaMime: contentType,
      mediaSize: bytes.length,
      replyToId: replyToId,
    );
  }

  Future<void> _insertMessage({
    required String conversationId,
    required String messageType,
    required String content,
    String? mediaPath,
    String? mediaMime,
    int? mediaSize,
    String? replyToId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'message_type': messageType,
      'media_path': mediaPath,
      'media_mime': mediaMime,
      'media_size': mediaSize,
      'reply_to_id': replyToId,
      'delivered_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> signedMediaUrl(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    final response = await _supabase.storage.from('chat-media').createSignedUrl(path, 60 * 60 * 6);
    return response;
  }

  Future<void> sendMessage(String conversationId, String content) {
    return sendText(conversationId: conversationId, content: content);
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.rpc('delete_chat_message', params: {'p_message_id': messageId});
    } catch (_) {
      await _supabase.from('messages').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': currentUserId,
        'content': '',
        'media_path': null,
      }).eq('id', messageId);
    }
  }

  Future<void> clearConversation(String conversationId) async {
    try {
      await _supabase.rpc('clear_conversation', params: {'p_conversation_id': conversationId});
    } catch (_) {
      await _supabase.from('messages').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': currentUserId,
        'content': '',
        'media_path': null,
      }).eq('conversation_id', conversationId);
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase.rpc('delete_conversation', params: {'p_conversation_id': conversationId});
    } catch (_) {
      await _supabase.from('conversations').delete().eq('id', conversationId);
    }
  }
}

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(Supabase.instance.client);
}
