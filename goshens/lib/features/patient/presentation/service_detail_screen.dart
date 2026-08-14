import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../comments/data/comment_repository.dart';
import '../../comments/presentation/comment_composer.dart';
import '../data/service_repository.dart';
import '../data/service_visuals.dart';
import 'widgets/home_comment_tile.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId, this.initialService});

  final String serviceId;
  final Map<String, dynamic>? initialService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceByIdProvider(serviceId));
    final commentsAsync = ref.watch(serviceCommentsProvider(serviceId));
    final service = serviceAsync.valueOrNull ?? initialService;

    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Service')),
        body: serviceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Could not load this service.\n$error')),
          data: (_) => const Center(child: Text('Service not found.')),
        ),
      );
    }

    final name = service['name'] as String? ?? 'Service';
    final description = service['description'] as String? ?? '';
    final duration = service['estimated_duration_minutes'];
    final images = serviceImagePaths(service)
        .map((path) => ref.read(serviceRepositoryProvider).publicImageUrl(path))
        .whereType<String>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(images[index], fit: BoxFit.cover),
                  );
                },
              ),
            )
          else
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(iconForService(service['icon_name'] as String?), size: 64, color: AppColors.primary),
            ),
          const SizedBox(height: 20),
          Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink(context))),
          if (duration != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('About $duration minutes', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(description, style: TextStyle(height: 1.5, fontSize: 16, color: AppColors.ink(context))),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.pushNamed(
                    RouteNames.patientBooking,
                    extra: <String, dynamic>{'serviceId': serviceId, 'serviceName': name},
                  ),
                  icon: Icon(Icons.calendar_month),
                  label: Text('Book'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showServiceCommentSheet(
                    context,
                    ref,
                    serviceId: serviceId,
                    serviceName: name,
                  ),
                  icon: Icon(Icons.chat_bubble_outline),
                  label: Text('Comment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Comments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink(context))),
          const SizedBox(height: 12),
          commentsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (error, _) => Text('Could not load comments.\n$error'),
            data: (comments) {
              if (comments.isEmpty) {
                return Text(
                  'No comments yet. Be the first to share your experience.',
                  style: TextStyle(color: AppColors.muted(context)),
                );
              }
              return Column(
                children: comments.map((comment) => HomeCommentTile(comment: comment)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
