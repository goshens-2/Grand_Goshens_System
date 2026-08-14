import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help & support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Center(child: GoshensLogo(size: 72, glow: true)),
          const SizedBox(height: 20),
          Text(
            'How can we help you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const SectionHeader('FAQs'),
          _buildFaqItem(
            context,
            'How do I book an appointment?',
            'Open Services, choose a treatment, then tap Book and pick a date and time preference.',
          ),
          _buildFaqItem(
            context,
            'How does check-in work?',
            'Once your appointment is approved, you will receive a QR code in the appointment details. Present this QR code to the clinic staff upon arrival.',
          ),
          _buildFaqItem(
            context,
            'Where can I find my prescriptions?',
            'Your prescriptions are available under "My Prescriptions" in the More tab.',
          ),
          const SizedBox(height: 32),
          Text(
            'Still need help?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.pushNamed(RouteNames.patientChat),
            icon: Icon(Icons.chat_bubble_outline),
            label: Text('Message Clinic'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: TextStyle(fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        Text(answer, style: TextStyle(height: 1.5, color: AppColors.muted(context))),
      ],
    );
  }
}
