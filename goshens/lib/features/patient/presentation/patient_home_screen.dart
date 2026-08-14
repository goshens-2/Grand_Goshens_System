import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/route_extras.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../comments/data/comment_repository.dart';
import '../../notifications/data/device_notifications.dart';
import '../../notifications/data/notification_repository.dart';
import '../data/appointment_repository.dart';
import '../data/clinic_repository.dart';
import '../data/profile_repository.dart';
import '../data/service_repository.dart';
import 'widgets/home_comment_tile.dart';
import 'widgets/rotating_service_cards.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileRepositoryProvider).getProfile();
    final upcomingApptAsync = ref.watch(upcomingAppointmentProvider);
    final clinicAsync = ref.watch(clinicSettingsProvider);
    final servicesAsync = ref.watch(publishedServicesProvider);
    final commentsAsync = ref.watch(approvedHomeCommentsProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(upcomingAppointmentProvider);
            ref.invalidate(userNotificationsProvider);
            ref.invalidate(currentProfileProvider);
            ref.invalidate(clinicSettingsProvider);
            ref.invalidate(publishedServicesProvider);
            ref.invalidate(approvedHomeCommentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const GoshensLogo(size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FutureBuilder(
                    future: profileAsync,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final profile = snapshot.data;
                      final name = profile?['full_name'] ?? 'Guest';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';
                      final avatarUrl = ref.read(profileRepositoryProvider)
                          .publicAvatarUrl(profile?['avatar_path'] as String?);
                      
                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pushNamed(RouteNames.patientProfileSetup),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null
                                  ? Text(
                                      initial,
                                      style: TextStyle(
                                        color: AppColors.ink(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.muted(context),
                                      ),
                                ),
                                Text(
                                  name.split(' ')[0],
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppColors.ink(context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  ),
                  Row(
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final count = ref.watch(unreadNotificationCountProvider);
                          return IconButton(
                            icon: Badge(
                              isLabelVisible: count > 0,
                              label: Text(count.toString()),
                              child: Icon(Icons.notifications_outlined, color: AppColors.ink(context)),
                            ),
                            onPressed: () {
                              DeviceNotifications.instance.initialize();
                              context.pushNamed(RouteNames.notifications);
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.chat_bubble_outline, color: AppColors.ink(context)),
                        onPressed: () => context.pushNamed(RouteNames.patientChat),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Upcoming Appointment Card
              upcomingApptAsync.when(
                data: (appt) {
                  if (appt == null) {
                    return _buildEmptyAppointmentCard(context);
                  }
                  return _buildUpcomingAppointmentCard(context, appt);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading appointment: $e'),
              ),
              
              const SizedBox(height: 32),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) {
                  context.pushNamed(
                    RouteNames.patientServices,
                    extra: {'query': value.trim()},
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search available services',
                  prefixIcon: Icon(Icons.search, color: AppColors.ink(context)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: AppColors.hairline(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              servicesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text('Could not load services.\n$error'),
                data: (services) {
                  final matches = query.isEmpty
                      ? services
                      : services.where((service) {
                          final name = (service['name'] as String? ?? '').toLowerCase();
                          final description = (service['description'] as String? ?? '').toLowerCase();
                          return name.contains(query) || description.contains(query);
                        }).toList();

                  if (query.isNotEmpty) {
                    if (matches.isEmpty) {
                      return Text('No matching services.', style: TextStyle(color: AppColors.muted(context)));
                    }
                    return Column(
                      children: matches.take(6).map((service) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(Icons.medical_services_outlined, color: AppColors.ink(context)),
                          ),
                          title: Text(service['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            service['description'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => context.pushNamed(RouteNames.patientServiceDetail, extra: service),
                        );
                      }).toList(),
                    );
                  }

                  return RotatingServiceCards(services: matches);
                },
              ),
              const SizedBox(height: 32),
              const SectionHeader('What patients say'),
              commentsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                error: (error, _) => Text('Comments will appear here after approval.\n$error', style: TextStyle(color: AppColors.muted(context))),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Text(
                      'Approved patient comments will show here.',
                      style: TextStyle(color: AppColors.muted(context)),
                    );
                  }
                  return Column(
                    children: comments.map((comment) => HomeCommentTile(comment: comment)).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Clinic Info
              clinicAsync.when(
                data: (clinic) {
                  if (clinic == null) return const SizedBox.shrink();
                  return _buildClinicInfoCard(context, clinic);
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyAppointmentCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset('assets/images/Goshens_logo.png', height: 60),
            const SizedBox(height: 16),
            Text(
              'No upcoming appointments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink(context),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your smile deserves great care.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted(context),
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                  onPressed: () {
                    context.pushNamed(RouteNames.patientServices);
                  },
              child: Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context, Map<String, dynamic> appt) {
    final serviceName = embeddedName(appt['services'], 'Appointment');
    final status = appt['status'];
    
    String displayDate = appt['requested_date'];
    String displayTime = appt['preferred_period'];

    if (appt['final_start_at'] != null) {
      final finalStart = DateTime.parse(appt['final_start_at']).toLocal();
      displayDate = DateFormat('EEEE, MMM d, yyyy').format(finalStart);
      displayTime = DateFormat('h:mm a').format(finalStart);
    }

    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.ink(context).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Appointment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toString().replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              serviceName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  displayDate,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  displayTime,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            if (status == 'scheduled' || status == 'approved') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: () {
                    context.pushNamed(RouteNames.patientAppointmentCard, extra: appt);
                  },
                  child: Text('View Appointment Card'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildClinicInfoCard(BuildContext context, Map<String, dynamic> clinic) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.hairline(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Clinic information',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context), fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              clinic['clinic_name'] ?? '',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(clinic['address'] ?? '', style: TextStyle(color: AppColors.muted(context))),
            const SizedBox(height: 12),
            Text('Dentist: ${clinic['dentist_name']}', style: TextStyle(color: AppColors.muted(context))),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.pushNamed(RouteNames.clinicInformation),
              child: Text('View Clinic Details'),
            ),
          ],
        ),
      ),
    );
  }
}
