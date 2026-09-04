import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/company_credits.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../auth/data/auth_actions.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinic tools')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
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
                      Text(
                        AppConstants.appName,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      SizedBox(height: 4),
                      Text('Everything you need to run the practice.', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Operations'),
          MenuTile(
            icon: Icons.insights_outlined,
            title: 'Analytics',
            subtitle: 'Visits, patients and clinic statistics',
            onTap: () => context.pushNamed(RouteNames.adminAnalytics),
          ),
          MenuTile(
            icon: Icons.people_outline,
            title: 'Patients',
            subtitle: 'Profiles, history and chat',
            onTap: () => context.pushNamed(RouteNames.adminPatientsList),
          ),
          MenuTile(
            icon: Icons.medication_outlined,
            title: 'Write prescription',
            subtitle: 'From today’s visits or a patient record',
            onTap: () => context.pushNamed(RouteNames.adminPrescription),
          ),
          const SizedBox(height: 8),
          const SectionHeader('Engagement'),
          MenuTile(
            icon: Icons.chat_bubble_outline,
            title: 'Patient messages',
            subtitle: 'WhatsApp-style clinic chat',
            onTap: () => context.pushNamed(RouteNames.adminChats),
          ),
          MenuTile(
            icon: Icons.rate_review_outlined,
            title: 'Patient comments',
            subtitle: 'Approve testimonials before they go live',
            onTap: () => context.pushNamed(RouteNames.adminComments),
          ),
          const SizedBox(height: 8),
          const SectionHeader('Account'),
          MenuTile(
            icon: Icons.settings_outlined,
            title: 'Clinic settings',
            subtitle: 'Name, address, phone and hours',
            onTap: () => context.pushNamed(RouteNames.adminClinicSettings),
          ),
          MenuTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Account settings',
            subtitle: 'Email and password',
            onTap: () => context.pushNamed(RouteNames.accountSettings),
          ),
          const SectionHeader('Appearance'),
          const ThemeModeTile(),
          MenuTile(
            icon: Icons.lock_outline,
            title: "Doctor's use only",
            subtitle: 'Passcode-protected service pricing',
            onTap: () => context.pushNamed(RouteNames.adminDoctorPricing),
          ),
          MenuTile(
            icon: Icons.logout,
            title: 'Sign out',
            destructive: true,
            onTap: () => confirmAndSignOut(context, ref),
          ),
          const SizedBox(height: 16),
          const Center(child: VisionTechnologiesCredit()),
        ],
      ),
    );
  }
}
