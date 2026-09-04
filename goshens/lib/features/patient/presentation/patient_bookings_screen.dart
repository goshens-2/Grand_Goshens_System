import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/route_extras.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/appointment_repository.dart';

class PatientBookingsScreen extends ConsumerStatefulWidget {
  const PatientBookingsScreen({super.key});

  @override
  ConsumerState<PatientBookingsScreen> createState() => _PatientBookingsScreenState();
}

class _PatientBookingsScreenState extends ConsumerState<PatientBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _cancellingAppointmentId;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.ink(context),
          unselectedLabelColor: AppColors.muted(context),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: FutureBuilder(
        future: ref.watch(appointmentRepositoryProvider).getPatientAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allAppointments = (snapshot.data ?? []).where((a) {
            return matchesQuery(_query, [
              embeddedName(a['services'], 'Appointment'),
              a['status'],
              a['requested_date'],
              a['final_start_at'],
              a['dentist_response'],
            ]);
          }).toList();

          final upcoming = allAppointments.where((a) {
            if (!['approved', 'scheduled'].contains(a['status'])) return false;
            final start = DateTime.tryParse(a['final_start_at']?.toString() ?? '');
            return start == null || !start.toLocal().isBefore(DateTime.now());
          }).toList();
          
          final pending = allAppointments
              .where((a) => a['status'] == 'pending_review')
              .toList();
          
          final history = allAppointments.where((a) {
            final id = a['id'];
            final inUpcoming = upcoming.any((u) => u['id'] == id);
            final inPending = pending.any((p) => p['id'] == id);
            return !inUpcoming && !inPending;
          }).toList();

          return Column(
            children: [
              ListSearchBar(
                hint: 'Search bookings',
                onChanged: (value) => setState(() => _query = value),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(upcoming, 'No upcoming appointments'),
                    _buildList(pending, 'No pending requests'),
                    _buildList(history, 'No past appointments'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String emptyMessage) {
    if (items.isEmpty) {
      return EmptyState(icon: Icons.event_busy_outlined, title: emptyMessage);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final appt = items[index];
        return _buildAppointmentCard(appt);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final serviceName = embeddedName(appt['services'], 'Appointment');
    final status = appt['status'] as String;
    
    String displayDate = appt['requested_date'];
    String displayTime = appt['preferred_period'];

    if (appt['final_start_at'] != null) {
      final finalStart = DateTime.parse(appt['final_start_at']).toLocal();
      displayDate = DateFormat('EEEE, MMM d, yyyy').format(finalStart);
      displayTime = DateFormat('h:mm a').format(finalStart);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    serviceName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink(context),
                        ),
                  ),
                ),
                StatusPill.fromAppointment(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.muted(context)),
                const SizedBox(width: 8),
                Text(displayDate, style: TextStyle(color: AppColors.muted(context))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.muted(context)),
                const SizedBox(width: 8),
                Text(displayTime, style: TextStyle(color: AppColors.muted(context))),
              ],
            ),
            if (appt['dentist_response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appt['dentist_response'],
                        style: TextStyle(fontSize: 13, color: AppColors.ink(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (['pending_review', 'approved', 'scheduled'].contains(status)) ...[
                  OutlinedButton(
                    onPressed: _cancellingAppointmentId == appt['id']
                        ? null
                        : () => _confirmCancellation(appt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: _cancellingAppointmentId == appt['id']
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (status == 'scheduled' || status == 'approved')
                  ElevatedButton(
                    onPressed: () {
                      context.pushNamed(RouteNames.patientAppointmentCard, extra: appt);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('View Card'),
                  )
                  else
                  OutlinedButton(
                    onPressed: () {
                      context.pushNamed(RouteNames.patientAppointmentCard, extra: appt);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('View Details'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancellation(Map<String, dynamic> appointment) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel appointment?'),
        content: Text(
          'This will cancel your request. You can submit another appointment request when you are ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel request'),
          ),
        ],
      ),
    );
    if (shouldCancel != true || !mounted) return;

    setState(() => _cancellingAppointmentId = appointment['id'] as String);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .cancelAppointment(appointment['id'] as String);
      ref.invalidate(upcomingAppointmentProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your appointment request was cancelled.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not cancel that appointment. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _cancellingAppointmentId = null);
    }
  }
}
