import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/premium_ui.dart';
import '../data/clinic_analytics.dart';
import 'admin_patient_history_sheet.dart';

/// Grouped patient list for a single analytics category (Clinic visits,
/// Pending requests, Upcoming, No shows, Cancelled/rejected, Doc registered
/// patients). Only patients belonging to that category are shown.
class AdminAnalyticsGroupScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsGroupScreen({super.key, required this.title, required this.patients});

  final String title;
  final List<PatientVisitSummary> patients;

  @override
  ConsumerState<AdminAnalyticsGroupScreen> createState() => _AdminAnalyticsGroupScreenState();
}

class _AdminAnalyticsGroupScreenState extends ConsumerState<AdminAnalyticsGroupScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.patients.where((patient) {
      return matchesQuery(_query, [patient.name, patient.phone, patient.email]);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          ListSearchBar(
            hint: 'Search by name, phone or email',
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(icon: Icons.people_outline, title: 'No matching patients')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final patient = filtered[index];
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
                            title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(patient.phone ?? 'No phone'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => showPatientHistorySheet(
                              context,
                              ref,
                              patientId: patient.patientId,
                              patientName: patient.name,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
