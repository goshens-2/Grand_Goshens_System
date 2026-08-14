import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/profile_repository.dart';

class HomeCommentTile extends ConsumerWidget {
  const HomeCommentTile({super.key, required this.comment});

  final Map<String, dynamic> comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (comment['author_name'] as String?)?.trim().isNotEmpty == true
        ? comment['author_name'] as String
        : 'Patient';
    final serviceName = comment['services'] is Map
        ? (comment['services']['name'] as String? ?? 'Dental service')
        : 'Dental service';
    final body = comment['body'] as String? ?? '';
    final avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(
          comment['author_avatar_path'] as String?,
        );
    final status = comment['status'] as String? ?? 'approved';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.ink(context),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink(context))),
                  const SizedBox(height: 2),
                  Text(
                    serviceName,
                    style: TextStyle(color: AppColors.highlight(context), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (status != 'approved') ...[
                    const SizedBox(height: 4),
                    Text(
                      status == 'pending' ? 'Waiting for doctor approval' : 'Not published',
                      style: TextStyle(
                        color: status == 'pending' ? AppColors.warning : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(body, style: TextStyle(height: 1.4, color: AppColors.ink(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
