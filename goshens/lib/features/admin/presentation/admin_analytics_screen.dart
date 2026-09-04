import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/clinic_analytics.dart';
import '../data/clinic_analytics_repository.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  late Future<ClinicAnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(clinicAnalyticsRepositoryProvider).loadSnapshot();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ref.read(clinicAnalyticsRepositoryProvider).loadSnapshot();
    });
    await _future;
  }

  void _openGroup(String title, List<PatientVisitSummary> patients) {
    context.pushNamed(
      RouteNames.adminAnalyticsGroup,
      extra: {'title': title, 'patients': patients},
    );
  }

  void _openClinicHistory(List<PatientVisitSummary> patients) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => _ClinicHistoryScreen(patients: patients)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: FutureBuilder<ClinicAnalyticsSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.insights_outlined,
              title: 'Could not load analytics',
              message: snapshot.error.toString(),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Visits are counted only when a patient checks in — by QR scan or a confirmed arrival.',
                  style: TextStyle(color: AppColors.muted(context), height: 1.35),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Patients enrolled',
                        value: '${data.enrolledPatients}',
                        icon: Icons.groups_outlined,
                        color: AppColors.primary,
                        onTap: () => context.pushNamed(RouteNames.adminEnrolledSearch),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Clinic visits',
                        value: '${data.totalVisits}',
                        icon: Icons.qr_code_scanner,
                        color: AppColors.secondary,
                        onTap: () => _openGroup('Clinic visits', data.patientsFor(AnalyticsGroup.clinicVisits)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Pending requests',
                        value: '${data.pendingRequests}',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                        onTap: () => _openGroup('Pending requests', data.patientsFor(AnalyticsGroup.pendingRequests)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Upcoming',
                        value: '${data.upcomingScheduled}',
                        icon: Icons.event_available_outlined,
                        color: AppColors.info,
                        onTap: () => _openGroup('Upcoming', data.patientsFor(AnalyticsGroup.upcoming)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'No-shows',
                        value: '${data.noShows}',
                        icon: Icons.person_off_outlined,
                        color: AppColors.error,
                        onTap: () => _openGroup('No-shows', data.patientsFor(AnalyticsGroup.noShows)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Cancelled / rejected',
                        value: '${data.cancelled}',
                        icon: Icons.cancel_outlined,
                        color: AppColors.textSecondary,
                        onTap: () => _openGroup('Cancelled / rejected', data.patientsFor(AnalyticsGroup.cancelled)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StatCard(
                  label: 'Doc registered patients',
                  value: '${data.docRegisteredPatients}',
                  icon: Icons.badge_outlined,
                  color: AppColors.gold,
                  onTap: () => _openGroup('Doc registered patients', data.patientsFor(AnalyticsGroup.docRegistered)),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _openClinicHistory(data.patients),
                  icon: const Icon(Icons.history),
                  label: const Text('Clinic history'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// All patients with their clinic visit counts — replaces the old inline
/// "Patient visit history" section with a single, simple button.
class _ClinicHistoryScreen extends StatefulWidget {
  const _ClinicHistoryScreen({required this.patients});

  final List<PatientVisitSummary> patients;

  @override
  State<_ClinicHistoryScreen> createState() => _ClinicHistoryScreenState();
}

class _ClinicHistoryScreenState extends State<_ClinicHistoryScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final patients = widget.patients.where((patient) {
      return matchesQuery(_query, [patient.name, patient.phone, patient.email]);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Clinic history')),
      body: Column(
        children: [
          ListSearchBar(
            hint: 'Search patients',
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: patients.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No matching patients',
                    message: 'Enrolled patients appear here with their check-in count.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      for (final patient in patients)
                        _PatientVisitTile(
                          patient: patient,
                          onTap: () => _openPatientVisits(context, patient),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _openPatientVisits(BuildContext context, PatientVisitSummary patient) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return _PatientVisitSheet(patient: patient, controller: controller);
          },
        );
      },
    );
  }
}

class _PatientVisitTile extends StatelessWidget {
  const _PatientVisitTile({required this.patient, required this.onTap});

  final PatientVisitSummary patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastVisit = patient.lastVisitAt == null
        ? 'No clinic visits yet'
        : 'Last visit ${DateFormat('d MMM yyyy').format(patient.lastVisitAt!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.hairline(context)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                    style: TextStyle(color: AppColors.ink(context), fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(lastVisit, style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${patient.visitCount}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink(context),
                      ),
                    ),
                    Text(
                      patient.visitCount == 1 ? 'visit' : 'visits',
                      style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppColors.faint(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientVisitSheet extends StatelessWidget {
  const _PatientVisitSheet({required this.patient, required this.controller});

  final PatientVisitSummary patient;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy');
    final timeFormat = DateFormat('h:mm a');

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          patient.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          patient.visitCount == 0
              ? 'This patient has not checked in at the clinic yet.'
              : '${patient.visitCount} clinic ${patient.visitCount == 1 ? 'visit' : 'visits'}',
          style: TextStyle(color: AppColors.muted(context)),
        ),
        if (patient.phone != null && patient.phone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(patient.phone!, style: TextStyle(color: AppColors.muted(context))),
        ],
        const SizedBox(height: 16),
        if (patient.visits.isEmpty)
          const EmptyState(
            icon: Icons.qr_code_2_outlined,
            title: 'No visits yet',
            message: 'A visit is recorded when their QR card is scanned or check-in is confirmed.',
          )
        else
          for (final visit in patient.visits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.hairline(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visit.serviceName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        StatusPill.fromAppointment(visit.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _VisitFact(icon: Icons.event, label: dateFormat.format(visit.visitedAt)),
                    _VisitFact(icon: Icons.schedule, label: timeFormat.format(visit.visitedAt)),
                    _VisitFact(icon: Icons.qr_code_scanner, label: visit.checkInMethod),
                    if (visit.reference != null && visit.reference!.isNotEmpty)
                      _VisitFact(icon: Icons.tag, label: 'Ref ${visit.reference}'),
                    if (visit.patientNote != null && visit.patientNote!.trim().isNotEmpty)
                      _VisitFact(icon: Icons.notes_outlined, label: visit.patientNote!.trim()),
                    if (visit.dentistNote != null && visit.dentistNote!.trim().isNotEmpty)
                      _VisitFact(icon: Icons.medical_information_outlined, label: visit.dentistNote!.trim()),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _VisitFact extends StatelessWidget {
  const _VisitFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.faint(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.muted(context), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
