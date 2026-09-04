import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/patient_repository.dart';
import 'admin_patient_demographics_sheet.dart';

/// Full appointment history for one patient, with a header button to view
/// their saved demographics (whoever entered them).
void showPatientHistorySheet(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
  required String patientName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return FutureBuilder<Map<String, dynamic>>(
            future: ref.read(patientRepositoryProvider).getPatientDetails(patientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data ?? const {};
              final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
              final appointments = List.from(data['appointments'] as List? ?? []);

              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile['full_name']?.toString() ?? patientName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showPatientDemographicsSheet(
                          context,
                          profile.isEmpty ? {'full_name': patientName} : profile,
                        ),
                        icon: const Icon(Icons.badge_outlined, size: 18),
                        label: const Text('View patient demographics'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointments.isEmpty ? 'No appointment history yet' : '${appointments.length} appointment(s)',
                    style: TextStyle(color: AppColors.muted(context)),
                  ),
                  const SizedBox(height: 16),
                  if (appointments.isEmpty)
                    const EmptyState(icon: Icons.event_busy_outlined, title: 'No appointments yet')
                  else
                    ...appointments.map((appt) => _HistoryTile(appointment: Map<String, dynamic>.from(appt as Map))),
                ],
              );
            },
          );
        },
      );
    },
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.appointment});

  final Map<String, dynamic> appointment;

  @override
  Widget build(BuildContext context) {
    final serviceName = appointment['services']?['name']?.toString() ?? 'Service';
    final rawDate = appointment['final_start_at'] ?? appointment['requested_date'];
    final parsed = DateTime.tryParse(rawDate?.toString() ?? '');
    final date = parsed == null ? (rawDate?.toString() ?? 'Date TBD') : DateFormat('EEE d MMM yyyy').format(parsed.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serviceName, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
                ],
              ),
            ),
            StatusPill.fromAppointment(appointment['status'] as String?),
          ],
        ),
      ),
    );
  }
}
