import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/admin_appointment_repository.dart';
import '../data/patient_repository.dart';

enum _PatientTimeFilter { all, tomorrow, nextDay, nextWeek, nextMonth }

/// Patient search now lives inside this Patients card/screen along with a
/// lightweight date filter, instead of a separate section on the dashboard.
class AdminPatientsListScreen extends ConsumerStatefulWidget {
  const AdminPatientsListScreen({super.key});

  @override
  ConsumerState<AdminPatientsListScreen> createState() => _AdminPatientsListScreenState();
}

class _AdminPatientsListScreenState extends ConsumerState<AdminPatientsListScreen> {
  var _query = '';
  var _filter = _PatientTimeFilter.all;

  Set<String> _patientIdsMatchingFilter(List<Map<String, dynamic>> appointments) {
    if (_filter == _PatientTimeFilter.all) return {};

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    DateTime rangeStart;
    DateTime rangeEndExclusive;
    switch (_filter) {
      case _PatientTimeFilter.tomorrow:
        rangeStart = startOfToday.add(const Duration(days: 1));
        rangeEndExclusive = startOfToday.add(const Duration(days: 2));
      case _PatientTimeFilter.nextDay:
        rangeStart = startOfToday.add(const Duration(days: 2));
        rangeEndExclusive = startOfToday.add(const Duration(days: 3));
      case _PatientTimeFilter.nextWeek:
        rangeStart = startOfToday.add(const Duration(days: 1));
        rangeEndExclusive = startOfToday.add(const Duration(days: 8));
      case _PatientTimeFilter.nextMonth:
        rangeStart = startOfToday.add(const Duration(days: 1));
        rangeEndExclusive = startOfToday.add(const Duration(days: 31));
      case _PatientTimeFilter.all:
        return {};
    }

    final ids = <String>{};
    for (final appt in appointments) {
      final raw = appt['final_start_at'] ?? appt['requested_date'];
      final date = DateTime.tryParse(raw?.toString() ?? '');
      if (date == null) continue;
      final local = date.toLocal();
      if (!local.isBefore(rangeStart) && local.isBefore(rangeEndExclusive)) {
        final patientId = appt['patient_id']?.toString();
        if (patientId != null) ids.add(patientId);
      }
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patients')),
      body: FutureBuilder(
        future: Future.wait([
          ref.watch(patientRepositoryProvider).getPatients(),
          ref.watch(adminAppointmentRepositoryProvider).getAllAppointments(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allPatients = List<Map<String, dynamic>>.from(snapshot.data![0] as List);
          final appointments = List<Map<String, dynamic>>.from(snapshot.data![1] as List);
          final filterIds = _patientIdsMatchingFilter(appointments);

          final patients = allPatients.where((patient) {
            final matchesSearch = matchesQuery(_query, [patient['full_name'], patient['phone'], patient['email']]);
            final matchesFilter = _filter == _PatientTimeFilter.all || filterIds.contains(patient['id']?.toString());
            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              ListSearchBar(hint: 'Search patients by name, phone or email', onChanged: (value) => setState(() => _query = value)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _timeFilterChip('All', _PatientTimeFilter.all),
                    _timeFilterChip('Tomorrow', _PatientTimeFilter.tomorrow),
                    _timeFilterChip('Next day', _PatientTimeFilter.nextDay),
                    _timeFilterChip('Next week', _PatientTimeFilter.nextWeek),
                    _timeFilterChip('Next month', _PatientTimeFilter.nextMonth),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: patients.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, title: 'No patients yet', message: 'New sign-ups will appear here.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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

  Widget _timeFilterChip(String label, _PatientTimeFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
