import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shows every demographic field saved on a patient's profile, regardless of
/// whether it was entered by the doctor (add-patient flow) or by the patient
/// themselves (profile setup).
void showPatientDemographicsSheet(BuildContext context, Map<String, dynamic> profile) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final name = profile['full_name']?.toString() ?? 'Patient';
      final age = _ageFromDob(profile['date_of_birth']);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text(
                'Patient demographics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
              ),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(color: AppColors.muted(context))),
              const SizedBox(height: 16),
              _DemographicRow(label: 'Name', value: name),
              _DemographicRow(label: 'Age', value: age ?? 'Not provided'),
              _DemographicRow(label: 'Gender', value: profile['gender']?.toString()),
              _DemographicRow(label: 'Residence', value: profile['address']?.toString()),
              _DemographicRow(label: 'Email', value: profile['email']?.toString()),
              _DemographicRow(label: 'Phone number', value: profile['phone']?.toString()),
              _DemographicRow(label: 'Emergency notes', value: profile['emergency_contact']?.toString()),
              _DemographicRow(label: 'Allergies / health notes', value: profile['allergies_or_notes']?.toString()),
            ],
          );
        },
      );
    },
  );
}

String? _ageFromDob(Object? dob) {
  if (dob == null) return null;
  final parsed = DateTime.tryParse(dob.toString());
  if (parsed == null) return null;
  final now = DateTime.now();
  var age = now.year - parsed.year;
  if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
    age--;
  }
  return '$age years';
}

class _DemographicRow extends StatelessWidget {
  const _DemographicRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.trim().isEmpty) ? 'Not provided' : value!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted(context))),
          const SizedBox(height: 4),
          Text(display, style: TextStyle(fontSize: 15, color: AppColors.ink(context))),
        ],
      ),
    );
  }
}
