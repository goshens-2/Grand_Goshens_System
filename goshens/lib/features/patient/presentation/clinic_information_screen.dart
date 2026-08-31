import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/clinic_repository.dart';

String formatClinicHours(dynamic hours) {
  if (hours == null) return 'Please call the clinic for working hours.';
  if (hours is Map) {
    return hours.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
  }
  return hours.toString();
}

class ClinicInformationScreen extends ConsumerWidget {
  const ClinicInformationScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.scheme}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicAsync = ref.watch(clinicSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Clinic information')),
      body: clinicAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load clinic details.\n$error')),
        data: (clinic) {
          final name = clinic?['clinic_name'] as String? ?? AppConstants.appName;
          final tagline = clinic?['tagline'] as String? ?? 'Creating Perfect Smiles';
          final address = clinic?['address'] as String? ?? 'Kampala, Uganda';
          final phone = clinic?['phone'] as String? ?? '';
          final email = clinic?['email'] as String? ?? '';
          final dentist = clinic?['dentist_name'] as String? ?? '';
          final hours = formatClinicHours(clinic?['working_days_hours']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: GoshensLogo(size: 88, glow: true)),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  tagline,
                  style: TextStyle(fontSize: 16, color: AppColors.muted(context)),
                  textAlign: TextAlign.center,
                ),
                if (dentist.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dentist: $dentist',
                    style: TextStyle(color: AppColors.muted(context)),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                _buildInfoCard(
                  context,
                  Icons.location_on_outlined,
                  'Address',
                  address,
                  actionLabel: 'Open map',
                  onAction: () => _open(
                    context,
                    Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  Icons.phone_outlined,
                  'Contact',
                  [if (phone.isNotEmpty) phone, if (email.isNotEmpty) email].join('\n'),
                  actionLabel: phone.isNotEmpty ? 'Call clinic' : null,
                  onAction: phone.isEmpty
                      ? null
                      : () => _open(context, Uri(scheme: 'tel', path: phone)),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _open(context, Uri(scheme: 'mailto', path: email)),
                      icon: Icon(Icons.email_outlined),
                      label: Text('Send email'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  Icons.access_time_outlined,
                  'Working Hours',
                  hours,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    String content, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(content.isEmpty ? 'Not available yet' : content, style: TextStyle(height: 1.5)),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
