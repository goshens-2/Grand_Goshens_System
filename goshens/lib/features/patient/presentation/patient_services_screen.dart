import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/service_repository.dart';
import '../data/service_visuals.dart';

class PatientServicesScreen extends ConsumerStatefulWidget {
  const PatientServicesScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<PatientServicesScreen> createState() => _PatientServicesScreenState();
}

class _PatientServicesScreenState extends ConsumerState<PatientServicesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(publishedServicesProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: Text('Our Services')),
      body: servicesAsync.when(
        data: (services) {
          final filtered = query.isEmpty
              ? services
              : services.where((service) {
                  final name = (service['name'] as String? ?? '').toLowerCase();
                  final description = (service['description'] as String? ?? '').toLowerCase();
                  return name.contains(query) || description.contains(query);
                }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search available services',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(icon: Icons.search_off, title: 'No matching services')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildServiceCard(context, ref, filtered[index]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, WidgetRef ref, Map<String, dynamic> service) {
    final imagePaths = serviceImagePaths(service);
    final imageUrl = ref.read(serviceRepositoryProvider).publicImageUrl(imagePaths.isEmpty ? null : imagePaths.first);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.pushNamed(
            RouteNames.patientServiceDetail,
            extra: service,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(iconForService(service['icon_name'] as String?), color: AppColors.primary, size: 40),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink(context),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted(context)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (service['estimated_duration_minutes'] != null) ...[
                          Icon(Icons.timer_outlined, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '~${service['estimated_duration_minutes']} mins',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            context.pushNamed(
                              RouteNames.patientBooking,
                              extra: {
                                'serviceId': service['id'],
                                'serviceName': service['name'],
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text('Book'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
