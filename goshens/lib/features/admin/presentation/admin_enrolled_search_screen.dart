import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import 'doctor_lock_gate.dart';

/// Opened from "Patients enrolled" in Analytics. Only a search bar is shown;
/// tapping it offers Records or Payment records.
class AdminEnrolledSearchScreen extends ConsumerWidget {
  const AdminEnrolledSearchScreen({super.key});

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_shared_outlined),
              title: const Text('Records'),
              subtitle: const Text('All patients, search and history'),
              onTap: () => Navigator.of(context).pop('records'),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payment records'),
              subtitle: const Text('Passcode protected'),
              onTap: () => Navigator.of(context).pop('payments'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;

    if (choice == 'records') {
      context.pushNamed(RouteNames.adminRecords);
      return;
    }

    final unlocked = await unlockDoctorFeature(context, ref);
    if (unlocked && context.mounted) {
      context.pushNamed(RouteNames.adminPaymentRecords);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patients enrolled')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openPicker(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairline(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: AppColors.muted(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Search patients', style: TextStyle(color: AppColors.muted(context))),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.muted(context)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the search bar to choose Records or Payment records.',
              style: TextStyle(color: AppColors.muted(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
