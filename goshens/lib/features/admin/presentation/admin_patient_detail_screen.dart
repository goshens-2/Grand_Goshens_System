import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../patient/data/profile_repository.dart';
import '../data/patient_repository.dart';

class AdminPatientDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> patientData;

  const AdminPatientDetailScreen({super.key, required this.patientData});

  @override
  ConsumerState<AdminPatientDetailScreen> createState() => _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends ConsumerState<AdminPatientDetailScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = ref.read(patientRepositoryProvider).getPatientDetails(widget.patientData['id'] as String);
  }

  Future<void> _reload() async {
    setState(() {
      _detailsFuture = ref.read(patientRepositoryProvider).getPatientDetails(widget.patientData['id'] as String);
    });
    await _detailsFuture;
  }

  Future<void> _writePrescription(Map<String, dynamic> profile, List appointments) async {
    final wrote = await context.pushNamed<Object?>(
      RouteNames.adminPrescription,
      extra: {
        'patientId': profile['id'],
        'patientName': profile['full_name'] ?? widget.patientData['full_name'] ?? 'Patient',
        'avatarPath': profile['avatar_path'],
        'appointments': appointments,
      },
    );
    if (wrote == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientData['full_name'] ?? 'Patient'),
      ),
      body: FutureBuilder(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data as Map<String, dynamic>;
          final profile = Map<String, dynamic>.from(data['profile'] as Map);
          final appointments = List.from(data['appointments'] as List? ?? []);
          final prescriptions = List.from(data['prescriptions'] as List? ?? []);
          final avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(profile['avatar_path'] as String?);
          final name = profile['full_name'] as String? ?? 'Unknown';

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                        const SizedBox(height: 6),
                        Text(profile['phone'] ?? 'No phone', style: TextStyle(color: AppColors.muted(context))),
                        if ((profile['email'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(profile['email'], style: TextStyle(color: AppColors.muted(context))),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.pushNamed(
                                  RouteNames.patientChat,
                                  extra: {
                                    'patientId': profile['id'],
                                    'title': name,
                                    'avatarPath': profile['avatar_path'],
                                  },
                                ),
                                icon: Icon(Icons.chat_bubble_outline),
                                label: Text('Message'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _writePrescription(profile, appointments),
                                icon: Icon(Icons.medication_outlined),
                                label: Text('Prescribe'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader('Appointments'),
                if (appointments.isEmpty)
                  const EmptyState(icon: Icons.event_busy_outlined, title: 'No appointments yet')
                else
                  ...appointments.map((appt) => _AppointmentTile(appointment: Map<String, dynamic>.from(appt as Map))),
                const SizedBox(height: 24),
                SectionHeader(
                  'Prescriptions',
                  actionLabel: 'Write',
                  onAction: () => _writePrescription(profile, appointments),
                ),
                if (prescriptions.isEmpty)
                  const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No prescriptions yet',
                    message: 'Write a script and the patient will be notified immediately.',
                  )
                else
                  ...prescriptions.map((pres) => _PrescriptionTile(prescription: Map<String, dynamic>.from(pres as Map))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final Map<String, dynamic> appointment;

  @override
  Widget build(BuildContext context) {
    final serviceName = appointment['services']?['name'] ?? 'Unknown service';
    final date = appointment['final_start_at'] ?? appointment['requested_date'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          title: Text(serviceName, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
          subtitle: Text('Date: $date'),
          trailing: StatusPill.fromAppointment(appointment['status'] as String?),
        ),
      ),
    );
  }
}

class _PrescriptionTile extends StatelessWidget {
  const _PrescriptionTile({required this.prescription});

  final Map<String, dynamic> prescription;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(prescription['created_at']?.toString() ?? '');
    final date = createdAt == null ? 'Prescription' : DateFormat('MMM d, yyyy').format(createdAt.toLocal());
    final pdfUrl = prescription['pdf_url'] as String?;
    final meds = (prescription['medications'] as List?)?.map((item) => item.toString()).where((item) => item.isNotEmpty).toList() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          title: Text(date, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
          subtitle: Text(
            [
              if ((prescription['doctor_name'] as String?)?.isNotEmpty == true) 'Doctor: ${prescription['doctor_name']}',
              if (meds.isNotEmpty) meds.take(2).join(', '),
            ].join('\n'),
          ),
          isThreeLine: meds.isNotEmpty,
          trailing: IconButton(
            icon: Icon(Icons.picture_as_pdf, color: pdfUrl == null ? AppColors.faint(context) : AppColors.primary),
            onPressed: pdfUrl == null
                ? null
                : () async {
                    final uri = Uri.parse(pdfUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
          ),
        ),
      ),
    );
  }
}
