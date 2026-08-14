import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../patient/data/service_visuals.dart';
import '../data/admin_service_repository.dart';

class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen> {
  var _query = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () async {
              await context.pushNamed(RouteNames.adminServiceEditor);
              setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed(RouteNames.adminServiceEditor);
          setState(() {});
        },
        backgroundColor: AppColors.cta(context),
        foregroundColor: AppColors.onCta(context),
        icon: Icon(Icons.add),
        label: Text('Add service'),
      ),
      body: FutureBuilder(
        future: ref.read(adminServiceRepositoryProvider).getAllServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final services = (snapshot.data ?? []).where((service) {
            return matchesQuery(_query, [service['name'], service['description'], service['icon_name']]);
          }).toList();
          if (services.isEmpty) {
            return Column(
              children: [
                ListSearchBar(hint: 'Search services', onChanged: (value) => setState(() => _query = value)),
                const Expanded(child: EmptyState(icon: Icons.medical_services_outlined, title: 'No services yet', message: 'Add your first treatment to start bookings.')),
              ],
            );
          }

          return Column(
            children: [
              ListSearchBar(hint: 'Search services', onChanged: (value) => setState(() => _query = value)),
              Expanded(
                child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final imagePaths = serviceImagePaths(service);
              final imageUrl = ref.read(adminServiceRepositoryProvider).publicImageUrl(
                    imagePaths.isEmpty ? null : imagePaths.first,
                  );
              final published = service['is_published'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await context.pushNamed(RouteNames.adminServiceEditor, extra: service);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.hairline(context)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl != null
                                ? Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover)
                                : Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    child: Icon(iconForService(service['icon_name'] as String?), color: AppColors.ink(context)),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                                const SizedBox(height: 4),
                                Text('${service['estimated_duration_minutes'] ?? '--'} mins', style: TextStyle(color: AppColors.muted(context))),
                              ],
                            ),
                          ),
                          StatusPill(published ? 'LIVE' : 'DRAFT', color: published ? AppColors.success : AppColors.faint(context)),
                        ],
                      ),
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
