import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/patient_repository.dart';

class AdminPatientsListScreen extends ConsumerStatefulWidget {
  const AdminPatientsListScreen({super.key});

  @override
  ConsumerState<AdminPatientsListScreen> createState() => _AdminPatientsListScreenState();
}

class _AdminPatientsListScreenState extends ConsumerState<AdminPatientsListScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patients')),
      body: FutureBuilder(
        future: ref.watch(patientRepositoryProvider).getPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final patients = (snapshot.data ?? []).where((patient) {
            return matchesQuery(_query, [patient['full_name'], patient['phone'], patient['email']]);
          }).toList();
          if (patients.isEmpty) {
            return Column(
              children: [
                ListSearchBar(hint: 'Search patients', onChanged: (value) => setState(() => _query = value)),
                const Expanded(child: EmptyState(icon: Icons.people_outline, title: 'No patients yet', message: 'New sign-ups will appear here.')),
              ],
            );
          }

          return Column(
            children: [
              ListSearchBar(hint: 'Search patients', onChanged: (value) => setState(() => _query = value)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final name = patient['full_name'] as String? ?? 'Unknown';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(color: AppColors.ink(context), fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(patient['phone'] ?? 'No phone'),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          onTap: () => context.pushNamed(RouteNames.adminPatientDetail, extra: patient),
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
