import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../patient/data/chat_repository.dart';
import '../../patient/data/profile_repository.dart';

class AdminChatInboxScreen extends ConsumerStatefulWidget {
  const AdminChatInboxScreen({super.key});

  @override
  ConsumerState<AdminChatInboxScreen> createState() => _AdminChatInboxScreenState();
}

class _AdminChatInboxScreenState extends ConsumerState<AdminChatInboxScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Patient messages')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(chatRepositoryProvider).watchInbox(),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = (snapshot.data ?? []).where((conversation) {
            final profile = conversation['profiles'];
            final name = profile is Map ? (profile['full_name'] as String? ?? 'Patient') : 'Patient';
            return matchesQuery(_query, [name, conversation['last_message_preview']]);
          }).toList();

          return Column(
            children: [
              ListSearchBar(
                hint: 'Search patients or messages',
                onChanged: (value) => setState(() => _query = value),
              ),
              Expanded(
                child: conversations.isEmpty
                    ? const EmptyState(icon: Icons.chat_bubble_outline, title: 'No patient chats yet.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: conversations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          final profile = conversation['profiles'];
                          final name = profile is Map
                              ? (profile['full_name'] as String? ?? 'Patient')
                              : 'Patient';
                          final avatarPath = profile is Map ? profile['avatar_path'] as String? : null;
                          final avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(avatarPath);
                          final preview = conversation['last_message_preview'] as String? ?? 'Tap to start chatting';
                          final unread = conversation['unread_count'] as int? ?? 0;
                          final updatedAt = DateTime.tryParse(
                                (conversation['last_message_at'] ?? conversation['updated_at']).toString(),
                              )?.toLocal();

                          return Dismissible(
                            key: ValueKey(conversation['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete this chat?'),
                                  content: Text('This removes the conversation with $name.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirmed != true) return false;
                              await ref.read(chatRepositoryProvider).deleteConversation(conversation['id'] as String);
                              return true;
                            },
                            child: Material(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(color: scheme.outline),
                                ),
                                leading: CircleAvatar(
                                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                  child: avatarUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                                ),
                                title: Text(name, style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600)),
                                subtitle: Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unread > 0 ? scheme.primary : scheme.onSurfaceVariant,
                                    fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (updatedAt != null)
                                      Text(
                                        DateFormat('h:mm a').format(updatedAt),
                                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                                      ),
                                    if (unread > 0) ...[
                                      const SizedBox(height: 6),
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColors.primary,
                                        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () => context.pushNamed(
                                  RouteNames.patientChat,
                                  extra: {
                                    'conversationId': conversation['id'],
                                    'title': name,
                                    'avatarPath': avatarPath,
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
