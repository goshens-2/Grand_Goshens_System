import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../patient/data/chat_repository.dart';
import '../../patient/data/profile_repository.dart';
import 'chat_media_viewer.dart';

class ClinicChatScreen extends ConsumerStatefulWidget {
  const ClinicChatScreen({
    super.key,
    this.conversationId,
    this.patientId,
    this.title,
    this.peerAvatarPath,
  });

  final String? conversationId;
  final String? patientId;
  final String? title;
  final String? peerAvatarPath;

  @override
  ConsumerState<ClinicChatScreen> createState() => _ClinicChatScreenState();
}

class _ClinicChatScreenState extends ConsumerState<ClinicChatScreen> {
  final _input = TextEditingController();
  final _urlCache = <String, String>{};
  Map<String, dynamic>? _conversation;
  Map<String, dynamic>? _replyTo;
  var _loading = true;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      Map<String, dynamic>? loaded;
      if (widget.conversationId != null) {
        loaded = await Supabase.instance.client
            .from('conversations')
            .select()
            .eq('id', widget.conversationId!)
            .maybeSingle();
      } else if (widget.patientId != null) {
        loaded = await repo.getOrCreatePatientConversation(patientId: widget.patientId);
      } else {
        loaded = await repo.getOrCreatePatientConversation();
      }
      if (!mounted) return;
      setState(() {
        _conversation = loaded;
        _loading = false;
      });
      if (loaded != null) {
        try {
          await repo.markConversationRead(loaded['id'] as String);
        } catch (_) {
          // Read receipts must never block opening the thread.
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat.\n$error'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<String?> _signed(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (_urlCache.containsKey(path)) return _urlCache[path];
    final url = await ref.read(chatRepositoryProvider).signedMediaUrl(path);
    if (url != null) _urlCache[path] = url;
    return url;
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    final conversation = _conversation;
    if (text.isEmpty || conversation == null || _sending) return;
    _input.clear();
    final replyId = _replyTo?['id'] as String?;
    setState(() {
      _replyTo = null;
      _sending = true;
    });
    try {
      await ref.read(chatRepositoryProvider).sendText(
            conversationId: conversation['id'] as String,
            content: text,
            replyToId: replyId,
          );
      await ref.read(chatRepositoryProvider).markConversationRead(conversation['id'] as String);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message not sent.\n$error'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendPickedBytes({
    required String type,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final conversation = _conversation;
    if (conversation == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).sendMedia(
            conversationId: conversation['id'] as String,
            messageType: type,
            bytes: Uint8List.fromList(bytes),
            fileName: fileName,
            contentType: contentType,
            caption: _input.text.trim().isEmpty ? null : _input.text.trim(),
            replyToId: _replyTo?['id'] as String?,
          );
      _input.clear();
      setState(() => _replyTo = null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send media.\n$error'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach(String kind) async {
    try {
    final picker = ImagePicker();
    if (kind == 'camera') {
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1600);
      if (photo == null) return;
      await _sendPickedBytes(
        type: 'image',
        bytes: await photo.readAsBytes(),
        fileName: photo.name,
        contentType: photo.mimeType ?? 'image/jpeg',
      );
      return;
    }
    if (kind == 'image') {
      final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
      if (photo == null) return;
      await _sendPickedBytes(
        type: 'image',
        bytes: await photo.readAsBytes(),
        fileName: photo.name,
        contentType: photo.mimeType ?? 'image/jpeg',
      );
      return;
    }
    if (kind == 'video') {
      final video = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 3));
      if (video == null) return;
      final bytes = await video.readAsBytes();
      if (bytes.length > 40 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please send a video smaller than 40 MB.')),
          );
        }
        return;
      }
      await _sendPickedBytes(
        type: 'video',
        bytes: bytes,
        fileName: video.name,
        contentType: video.mimeType ?? 'video/mp4',
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    if (file!.bytes!.length > 20 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please send a file smaller than 20 MB.')),
        );
      }
      return;
    }
    await _sendPickedBytes(
      type: 'file',
      bytes: file.bytes!,
      fileName: file.name,
      contentType: file.extension == 'pdf' ? 'application/pdf' : 'application/octet-stream',
    );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach that file.\n$error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openAttachSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _attach('camera');
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_outlined),
              title: Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _attach('image');
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam_outlined),
              title: Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _attach('video');
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _attach('file');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peerUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(widget.peerAvatarPath);
    final title = widget.title ?? 'Goshen Clinic';

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('Chat is currently unavailable.')),
      );
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              backgroundImage: peerUrl != null ? NetworkImage(peerUrl) : null,
              child: peerUrl == null
                  ? Icon(
                      widget.conversationId == null ? Icons.local_hospital : Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleThreadAction(value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear chat')),
              PopupMenuItem(value: 'delete', child: Text('Delete conversation')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(chatRepositoryProvider).getMessagesStream(_conversation!['id'] as String),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nSay hello to start the conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    ref.read(chatRepositoryProvider).markConversationRead(_conversation!['id'] as String);
                  } catch (_) {}
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    final previous = index == messages.length - 1 ? null : messages[messages.length - 2 - index];
                    final showDate = previous == null || !_sameDay(msg['created_at'], previous['created_at']);
                    final isMe = msg['sender_id'] == currentUserId;
                    final reply = _lookup(messages, msg['reply_to_id'] as String?);
                    final deleted = msg['deleted_at'] != null;

                    return Column(
                      children: [
                        if (showDate) _DateChip(label: _dateLabel(msg['created_at'])),
                        _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          reply: deleted ? null : reply,
                          resolveUrl: _signed,
                          onReply: deleted ? () {} : () => setState(() => _replyTo = msg),
                          onLongPress: () => _messageActions(msg, isMe: isMe, deleted: deleted),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_replyTo != null)
            Container(
              color: AppColors.card(context),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Container(width: 3, height: 36, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _replyTo!['content']?.toString().isNotEmpty == true
                          ? _replyTo!['content']
                          : (_replyTo!['message_type'] ?? 'Message'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.card(context),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: AppColors.ink(context)),
                    onPressed: _sending ? null : _openAttachSheet,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sending ? null : _sendText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _lookup(List<Map<String, dynamic>> messages, String? id) {
    if (id == null) return null;
    for (final message in messages) {
      if (message['id'] == id) return message;
    }
    return null;
  }

  bool _sameDay(dynamic a, dynamic b) {
    final first = DateTime.tryParse(a?.toString() ?? '')?.toLocal();
    final second = DateTime.tryParse(b?.toString() ?? '')?.toLocal();
    if (first == null || second == null) return true;
    return first.year == second.year && first.month == second.month && first.day == second.day;
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  Future<void> _handleThreadAction(String value) async {
    final conversation = _conversation;
    if (conversation == null) return;
    final id = conversation['id'] as String;
    if (value == 'clear') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Clear this chat?'),
          content: Text('All messages in this conversation will be removed for you and the clinic.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Clear chat')),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await ref.read(chatRepositoryProvider).clearConversation(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat cleared.')));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not clear chat.\n$error'), backgroundColor: AppColors.error),
          );
        }
      }
      return;
    }
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Delete conversation?'),
          content: Text('This removes the entire thread. You can start a new chat afterwards.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Delete')),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await ref.read(chatRepositoryProvider).deleteConversation(id);
        if (mounted) Navigator.of(context).maybePop();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete conversation.\n$error'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _messageActions(Map<String, dynamic> message, {required bool isMe, required bool deleted}) async {
    if (deleted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('Reply'),
              onTap: () => Navigator.pop(sheetContext, 'reply'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Delete message'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'reply') {
      setState(() => _replyTo = message);
      return;
    }
    if (action == 'delete') {
      try {
        await ref.read(chatRepositoryProvider).deleteMessage(message['id'] as String);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete message.\n$error'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card(context).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.reply,
    required this.resolveUrl,
    required this.onReply,
    required this.onLongPress,
  });

  final Map<String, dynamic> message;
  final bool isMe;
  final Map<String, dynamic>? reply;
  final Future<String?> Function(String? path) resolveUrl;
  final VoidCallback onReply;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(message['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final time = DateFormat('h:mm a').format(createdAt);
    final type = message['message_type'] as String? ?? 'text';
    final content = message['content'] as String? ?? '';
    final read = message['is_read'] == true || message['read_at'] != null;
    final deleted = message['deleted_at'] != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: deleted ? null : onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: deleted
              ? Text(
                  'This message was deleted',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isMe ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (reply != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.white : AppColors.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reply!['content']?.toString().isNotEmpty == true
                        ? reply!['content']
                        : (reply!['message_type'] ?? 'Message'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isMe ? Colors.white : AppColors.ink(context), fontSize: 12),
                  ),
                ),
              if (type == 'image')
                FutureBuilder<String?>(
                  future: resolveUrl(message['media_path'] as String?),
                  builder: (context, snapshot) {
                    final url = snapshot.data;
                    if (url == null) {
                      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChatMediaViewer(url: url, type: 'image')),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(url, height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              if (type == 'video')
                FutureBuilder<String?>(
                  future: resolveUrl(message['media_path'] as String?),
                  builder: (context, snapshot) {
                    final url = snapshot.data;
                    return GestureDetector(
                      onTap: url == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ChatMediaViewer(url: url, type: 'video')),
                              ),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
                      ),
                    );
                  },
                ),
              if (type == 'file')
                FutureBuilder<String?>(
                  future: resolveUrl(message['media_path'] as String?),
                  builder: (context, snapshot) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.insert_drive_file, color: isMe ? Colors.white : AppColors.ink(context)),
                      title: Text(
                        content.isNotEmpty ? content : 'Document',
                        style: TextStyle(color: isMe ? Colors.white : AppColors.ink(context), fontWeight: FontWeight.w600),
                      ),
                      onTap: snapshot.data == null
                          ? null
                          : () => launchUrl(Uri.parse(snapshot.data!), mode: LaunchMode.externalApplication),
                    );
                  },
                ),
              if (content.isNotEmpty && type != 'file') ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content,
                    style: TextStyle(color: isMe ? Colors.white : AppColors.ink(context), fontSize: 15, height: 1.35),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(color: isMe ? Colors.white70 : AppColors.muted(context), fontSize: 10),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: read ? const Color(0xFF34B7F1) : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
