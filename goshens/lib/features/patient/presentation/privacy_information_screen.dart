import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';

class PrivacyInformationScreen extends StatelessWidget {
  const PrivacyInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Privacy policy'),
            const SizedBox(height: 16),
            const Text(
              'At Goshens Dental Care, we take your privacy seriously. This privacy policy explains how we collect, use, and protect your personal and medical information.',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            Text(
              '1. Information Collection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We collect information you provide directly to us when you create an account, book an appointment, or communicate with us. This includes your name, contact details, and medical history.',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            Text(
              '2. Data Security',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your data is securely stored and transmitted using industry-standard encryption protocols. We implement strict row-level security to ensure your records are only accessible to you and authorized clinic staff.',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
