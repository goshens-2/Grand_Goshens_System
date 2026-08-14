import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../comments/data/comment_repository.dart';
import '../../patient/presentation/widgets/home_comment_tile.dart';

class AdminCommentsScreen extends ConsumerStatefulWidget {
  const AdminCommentsScreen({super.key});

  @override
  ConsumerState<AdminCommentsScreen> createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends ConsumerState<AdminCommentsScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(adminCommentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Patient comments')),
      body: commentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load comments.\n$error')),
        data: (comments) {
          final filtered = comments.where((comment) {
            return matchesQuery(_query, [
              comment['body'],
              comment['author_name'],
              comment['status'],
              comment['services']?['name'],
            ]);
          }).toList();
          final pending = filtered.where((comment) => comment['status'] == 'pending').toList();
          final reviewed = filtered.where((comment) => comment['status'] != 'pending').toList();

          return Column(
            children: [
              ListSearchBar(hint: 'Search comments', onChanged: (value) => setState(() => _query = value)),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(icon: Icons.rate_review_outlined, title: 'No comments yet')
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(adminCommentsProvider),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SectionHeader('Pending review'),
                            const SizedBox(height: 8),
                            if (pending.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No comments waiting for approval.'),
                                ),
                              )
                            else
                              ...pending.map((comment) => _AdminCommentCard(comment: comment)),
                            const SizedBox(height: 24),
                            const SectionHeader('Reviewed'),
                            const SizedBox(height: 8),
                            ...reviewed.map((comment) => _AdminCommentCard(comment: comment)),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminCommentCard extends ConsumerWidget {
  const _AdminCommentCard({required this.comment});

  final Map<String, dynamic> comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = comment['status'] as String? ?? 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeCommentTile(comment: comment),
        if (status == 'pending')
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _review(context, ref, 'rejected'),
                    child: Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _review(context, ref, 'approved'),
                    child: Text('Approve'),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              status == 'approved' ? 'Visible on the patient home page' : 'Hidden from patients',
              style: TextStyle(color: status == 'approved' ? AppColors.success : AppColors.muted(context)),
            ),
          ),
      ],
    );
  }

  Future<void> _review(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(commentRepositoryProvider).reviewComment(
            commentId: comment['id'] as String,
            status: status,
          );
      ref.invalidate(adminCommentsProvider);
      ref.invalidate(pendingCommentsProvider);
      ref.invalidate(approvedHomeCommentsProvider);
      ref.invalidate(serviceCommentsProvider(comment['service_id'] as String));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'approved' ? 'Comment published.' : 'Comment rejected.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
