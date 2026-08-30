import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
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
                      Text('Goshen Dental Care', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
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
          const SizedBox(height: 8),
          const SectionHeader('Account'),
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
