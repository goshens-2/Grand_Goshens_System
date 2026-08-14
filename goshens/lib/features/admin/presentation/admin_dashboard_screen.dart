import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../comments/data/comment_repository.dart';
import '../../notifications/data/device_notifications.dart';
import '../../notifications/data/notification_repository.dart';
import '../data/admin_appointment_repository.dart';
import 'appointment_review_sheet.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Future<({List<Map<String, dynamic>> pending, List<Map<String, dynamic>> today})> _boardFuture;

  @override
  void initState() {
    super.initState();
    _boardFuture = _loadBoard();
  }

  Future<({List<Map<String, dynamic>> pending, List<Map<String, dynamic>> today})> _loadBoard() async {
    final repo = ref.read(adminAppointmentRepositoryProvider);
    final results = await Future.wait([
      repo.getPendingRequests(),
      repo.getTodayAppointments(),
    ]);
    return (
      pending: List<Map<String, dynamic>>.from(results[0]),
      today: List<Map<String, dynamic>>.from(results[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final pendingComments = ref.watch(pendingCommentsProvider).valueOrNull ?? [];

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(pendingCommentsProvider);
          setState(() => _boardFuture = _loadBoard());
          await _boardFuture;
        },
        child: FutureBuilder(
          future: _boardFuture,
          builder: (context, snapshot) {
            final pending = snapshot.data?.pending ?? [];
            final today = snapshot.data?.today ?? [];
            final loading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _HeroHeader(unread: unread)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Pending',
                              value: loading ? '—' : '${pending.length}',
                              icon: Icons.hourglass_top_rounded,
                              color: AppColors.warning,
                              onTap: () => context.pushNamed(RouteNames.adminAppointments),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: "Today's visits",
                              value: loading ? '—' : '${today.length}',
                              icon: Icons.event_available_outlined,
                              color: AppColors.primary,
                              onTap: () => context.pushNamed(RouteNames.adminAppointments),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Comments',
                              value: '${pendingComments.length}',
                              icon: Icons.rate_review_outlined,
                              color: AppColors.secondary,
                              onTap: () => context.pushNamed(RouteNames.adminComments),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: 'Messages',
                              value: 'Chat',
                              icon: Icons.chat_bubble_outline,
                              color: AppColors.accent,
                              onTap: () => context.pushNamed(RouteNames.adminChats),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SectionHeader(
                        'Pending requests',
                        actionLabel: pending.isEmpty ? null : 'See all',
                        onAction: pending.isEmpty ? null : () => context.pushNamed(RouteNames.adminAppointments),
                      ),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (pending.isEmpty)
                        const _SoftEmpty(icon: Icons.inbox_outlined, title: 'You are all caught up', message: 'No appointment requests waiting.')
                      else
                        ...pending.map((req) => _PendingRequestCard(
                              request: req,
                              onReview: () => showAppointmentReviewSheet(
                                context: context,
                                ref: ref,
                                request: req,
                                onChanged: () => setState(() => _boardFuture = _loadBoard()),
                              ),
                            )),
                      const SizedBox(height: 24),
                      SectionHeader(
                        "Today's schedule",
                        actionLabel: 'Open',
                        onAction: () => context.pushNamed(RouteNames.adminAppointments),
                      ),
                      if (!loading && today.isEmpty)
                        const _SoftEmpty(icon: Icons.calendar_today_outlined, title: 'No visits today', message: 'Approved appointments will appear here.')
                      else
                        ...today.map((appt) => _TodayVisitCard(
                              appointment: appt,
                              time: _formatAppointmentTime(appt['final_start_at']),
                              onTap: () => context.pushNamed(RouteNames.adminVisitNote, extra: appt),
                            )),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatAppointmentTime(dynamic value) {
    if (value == null) return 'TBD';
    final dateTime = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dateTime == null) return 'TBD';
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GoshensLogo(size: 52, glow: true),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goshens Dental Care',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Admin console',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      DeviceNotifications.instance.initialize();
                      context.pushNamed(RouteNames.notifications);
                    },
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: Icon(Icons.notifications_outlined, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Run the clinic with clarity.',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                'Review requests, keep today’s chair time tight, and stay close to every patient.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  QuickActionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onTap: () => context.pushNamed(RouteNames.adminQrScanner),
                  ),
                  const SizedBox(width: 10),
                  QuickActionButton(
                    icon: Icons.people_alt_outlined,
                    label: 'Patients',
                    onTap: () => context.pushNamed(RouteNames.adminPatientsList),
                  ),
                  const SizedBox(width: 10),
                  QuickActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Clinic',
                    onTap: () => context.pushNamed(RouteNames.adminClinicSettings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({required this.request, required this.onReview});

  final Map<String, dynamic> request;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final name = request['profiles']?['full_name'] ?? 'Unknown';
    final service = request['services']?['name'] ?? 'Service';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline(context)),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.warning.withValues(alpha: 0.15),
              child: Text(
                name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                style: TextStyle(color: AppColors.ink(context), fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.toString(), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                  const SizedBox(height: 4),
                  Text('$service · ${request['requested_date']} · ${request['preferred_period']}', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
                ],
              ),
            ),
            FilledButton(
              onPressed: onReview,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cta(context),
                foregroundColor: AppColors.onCta(context),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Text('Review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayVisitCard extends StatelessWidget {
  const _TodayVisitCard({required this.appointment, required this.time, required this.onTap});

  final Map<String, dynamic> appointment;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = appointment['profiles']?['full_name'] ?? 'Unknown';
    final service = appointment['services']?['name'] ?? 'Service';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairline(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(time, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                      Text('IN', style: TextStyle(fontSize: 10, color: AppColors.muted(context), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString(), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
                      const SizedBox(height: 4),
                      Text(service.toString(), style: TextStyle(color: AppColors.muted(context))),
                    ],
                  ),
                ),
                StatusPill.fromAppointment(appointment['status'] as String?),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftEmpty extends StatelessWidget {
  const _SoftEmpty({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted(context))),
        ],
      ),
    );
  }
}
