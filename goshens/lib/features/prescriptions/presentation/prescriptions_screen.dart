import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../auth/data/auth_repository.dart';
import '../data/prescription_repository.dart';
import '../domain/prescription.dart';

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    if (user == null) {
      return const Scaffold(
        body: EmptyState(icon: Icons.lock_outline, title: 'Sign in to see prescriptions'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My prescriptions'),
      ),
      body: FutureBuilder<List<Prescription>>(
        future: ref.read(prescriptionRepositoryProvider).getPatientPrescriptions(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final prescriptions = (snapshot.data ?? []).where((pres) {
            return matchesQuery(_query, [pres.doctorName, pres.instructions, ...pres.medications]);
          }).toList();
          if (prescriptions.isEmpty) {
            return Column(
              children: [
                ListSearchBar(hint: 'Search prescriptions', onChanged: (value) => setState(() => _query = value)),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No prescriptions yet',
                    message: 'When the dentist writes a script for you, it will appear here.',
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              ListSearchBar(hint: 'Search prescriptions', onChanged: (value) => setState(() => _query = value)),
              Expanded(
                child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final pres = prescriptions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('MMM d, yyyy').format(pres.createdAt.toLocal()),
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink(context)),
                              ),
                            ),
                            StatusPill(pres.doctorName, color: AppColors.secondary),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Medications', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink(context))),
                        const SizedBox(height: 6),
                        ...pres.medications.map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $m', style: TextStyle(color: AppColors.muted(context), height: 1.4)),
                            )),
                        const SizedBox(height: 12),
                        Text('Instructions', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink(context))),
                        const SizedBox(height: 6),
                        Text(pres.instructions, style: TextStyle(color: AppColors.muted(context), height: 1.45)),
                        if (pres.pdfUrl != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(pres.pdfUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open the PDF')),
                                  );
                                }
                              },
                              icon: Icon(Icons.picture_as_pdf),
                              label: Text('Download PDF'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
