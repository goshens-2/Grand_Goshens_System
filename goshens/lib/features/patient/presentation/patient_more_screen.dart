import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../auth/data/auth_actions.dart';

class PatientMoreScreen extends ConsumerWidget {
  const PatientMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                GoshensLogo(size: 48, glow: true),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Goshen Dental Care', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      SizedBox(height: 4),
                      Text('Your smile, thoughtfully managed.', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Your care'),
          MenuTile(
            icon: Icons.person_outline,
            title: 'My profile',
            subtitle: 'Photo, phone and health notes',
            onTap: () => context.pushNamed(RouteNames.patientProfileSetup),
          ),
          MenuTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Account settings',
            subtitle: 'Email and password',
            onTap: () => context.pushNamed(RouteNames.accountSettings),
          ),
          MenuTile(
            icon: Icons.chat_bubble_outline,
            title: 'Message clinic',
            subtitle: 'Chat with the dentist in real time',
            onTap: () => context.pushNamed(RouteNames.patientChat),
          ),
          MenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'My prescriptions',
            subtitle: 'Download and review your scripts',
            onTap: () => context.pushNamed(RouteNames.patientPrescriptions),
          ),
          const SizedBox(height: 8),
          const SectionHeader('Clinic'),
          MenuTile(
            icon: Icons.local_hospital_outlined,
            title: 'Clinic information',
            subtitle: 'Address, hours and contact',
            onTap: () => context.pushNamed(RouteNames.clinicInformation),
          ),
          MenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Appointments, comments and chat',
            onTap: () => context.pushNamed(RouteNames.notifications),
          ),
          const ThemeModeTile(),
          const SizedBox(height: 8),
          const SectionHeader('Support'),
          MenuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy information',
            onTap: () => context.pushNamed(RouteNames.privacyInformation),
          ),
          MenuTile(
            icon: Icons.help_outline,
            title: 'Help & support',
            onTap: () => context.pushNamed(RouteNames.helpSupport),
          ),
          MenuTile(
            icon: Icons.logout,
            title: 'Sign out',
            destructive: true,
            onTap: () => confirmAndSignOut(context, ref),
          ),
        ],
      ),
    );
  }
}
