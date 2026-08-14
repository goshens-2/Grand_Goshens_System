import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/comment_repository.dart';

Future<void> showServiceCommentSheet(
  BuildContext context,
  WidgetRef ref, {
  required String serviceId,
  required String serviceName,
}) async {
  final controller = TextEditingController();
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Comment on $serviceName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink(context),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The doctor reviews every comment before it appears on the home page.',
                  style: TextStyle(color: AppColors.muted(context)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setModalState(() => saving = true);
                          try {
                            await ref.read(commentRepositoryProvider).submitComment(
                                  serviceId: serviceId,
                                  body: controller.text,
                                );
                            ref.invalidate(serviceCommentsProvider(serviceId));
                            ref.invalidate(approvedHomeCommentsProvider);
                            ref.invalidate(pendingCommentsProvider);
                            ref.invalidate(adminCommentsProvider);
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Comment sent. It will appear after the doctor approves it.'),
                                ),
                              );
                            }
                          } catch (error) {
                            setModalState(() => saving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString()), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Submit comment'),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  controller.dispose();
}
