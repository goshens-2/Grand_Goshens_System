import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/premium_ui.dart';
import '../data/patient_repository.dart';
import 'admin_patient_history_sheet.dart';

enum _RecordsFilter { all, today, lastWeek, lastMonth }

/// Records-only view: every patient in the system with search + a simple
/// filter. Tapping a patient opens their full appointment history.
class AdminRecordsScreen extends ConsumerStatefulWidget {
  const AdminRecordsScreen({super.key});

  @override
  ConsumerState<AdminRecordsScreen> createState() => _AdminRecordsScreenState();
}

class _AdminRecordsScreenState extends ConsumerState<AdminRecordsScreen> {
  var _query = '';
  var _filter = _RecordsFilter.all;

  bool _matchesFilter(Map<String, dynamic> patient) {
    if (_filter == _RecordsFilter.all) return true;
    final createdAt = DateTime.tryParse(patient['created_at']?.toString() ?? '');
    if (createdAt == null) return false;
    final now = DateTime.now();
    switch (_filter) {
      case _RecordsFilter.today:
        return createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
      case _RecordsFilter.lastWeek:
        return now.difference(createdAt) <= const Duration(days: 7);
      case _RecordsFilter.lastMonth:
        return now.difference(createdAt) <= const Duration(days: 31);
      case _RecordsFilter.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(patientRepositoryProvider).getPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final patients = (snapshot.data ?? [])
              .where((p) => matchesQuery(_query, [p['full_name'], p['phone'], p['email']]))
              .where(_matchesFilter)
              .toList();

          return Column(
            children: [
              ListSearchBar(
                hint: 'Search patients',
                onChanged: (value) => setState(() => _query = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(label: 'All', selected: _filter == _RecordsFilter.all, onTap: () => setState(() => _filter = _RecordsFilter.all)),
                    _FilterChip(label: 'Today', selected: _filter == _RecordsFilter.today, onTap: () => setState(() => _filter = _RecordsFilter.today)),
                    _FilterChip(label: 'Last week', selected: _filter == _RecordsFilter.lastWeek, onTap: () => setState(() => _filter = _RecordsFilter.lastWeek)),
                    _FilterChip(label: 'Last month', selected: _filter == _RecordsFilter.lastMonth, onTap: () => setState(() => _filter = _RecordsFilter.lastMonth)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: patients.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, title: 'No matching patients')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          final name = patient['full_name']?.toString() ?? 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text(patient['phone']?.toString() ?? 'No phone'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => showPatientHistorySheet(
                                  context,
                                  ref,
                                  patientId: patient['id'] as String,
                                  patientName: name,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}
