import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/route_extras.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/admin_appointment_repository.dart';
import 'appointment_review_sheet.dart';

class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends ConsumerState<AdminAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var _query = '';

  @override
  void initState() {
    super.initState();
    final startIndex = widget.initialTab == 'today' ? 1 : (widget.initialTab == 'all' ? 2 : 0);
    _tabController = TabController(length: 3, vsync: this, initialIndex: startIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.ink(context),
          unselectedLabelColor: AppColors.muted(context),
          indicatorColor: AppColors.ink(context),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Today'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Column(
        children: [
          ListSearchBar(
            hint: 'Search patients, services or dates',
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingView(context, ref),
                _buildTodayView(context, ref),
                _buildAllView(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingView(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.watch(adminAppointmentRepositoryProvider).getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = (snapshot.data ?? []).where((req) {
          return matchesQuery(_query, [
            embeddedName(req['profiles']),
            embeddedName(req['services'], 'Service'),
            req['requested_date'],
            req['preferred_period'],
          ]);
        }).toList();
        if (requests.isEmpty) {
          return const EmptyState(icon: Icons.inbox_outlined, title: 'No pending requests', message: 'New booking requests will land here.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: AppColors.hairline(context))),
                  title: Text(embeddedName(req['profiles']), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                  subtitle: Text('${embeddedName(req['services'], 'Service')}\nRequested: ${req['requested_date']} (${req['preferred_period']})'),
                  isThreeLine: true,
                  trailing: const StatusPill('REVIEW', color: AppColors.warning),
                  onTap: () => showAppointmentReviewSheet(
                    context: context,
                    ref: ref,
                    request: req,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTodayView(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.watch(adminAppointmentRepositoryProvider).getTodayAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = (snapshot.data ?? []).where((appt) {
          return matchesQuery(_query, [
            embeddedName(appt['profiles']),
            embeddedName(appt['services'], 'Service'),
            appt['final_start_at'],
            appt['status'],
          ]);
        }).toList();
        if (appointments.isEmpty) {
          return const EmptyState(icon: Icons.event_available_outlined, title: 'No visits today');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appt = appointments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: AppColors.hairline(context))),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.person_outline, color: AppColors.ink(context)),
                  ),
                  title: Text(embeddedName(appt['profiles']), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                  subtitle: Text('${embeddedName(appt['services'], 'Service')}\nTime: ${_formatAppointmentTime(appt['final_start_at'])}'),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.cta(context), foregroundColor: AppColors.onCta(context)),
                    onPressed: () => context.pushNamed(RouteNames.adminVisitNote, extra: appt),
                    child: Text('Note'),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllView(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.watch(adminAppointmentRepositoryProvider).getAllAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = (snapshot.data ?? []).where((appt) {
          return matchesQuery(_query, [
            embeddedName(appt['profiles']),
            embeddedName(appt['services'], 'Service'),
            appt['final_start_at'] ?? appt['requested_date'],
            appt['status'],
          ]);
        }).toList();
        if (appointments.isEmpty) {
          return const EmptyState(icon: Icons.calendar_month_outlined, title: 'No appointments found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appt = appointments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: AppColors.hairline(context))),
                  title: Text(embeddedName(appt['profiles']), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                  subtitle: Text('${embeddedName(appt['services'], 'Service')}\nDate: ${_formatAppointmentDate(appt['final_start_at'] ?? appt['requested_date'])}'),
                  trailing: StatusPill.fromAppointment(appt['status'] as String?),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatAppointmentTime(dynamic value) {
    final dateTime = _parseDate(value);
    if (dateTime == null) return 'Unknown';
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatAppointmentDate(dynamic value) {
    final dateTime = _parseDate(value);
    if (dateTime == null) return value?.toString() ?? 'Unknown';
    final local = dateTime.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
