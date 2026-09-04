import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/patient_repository.dart';

/// Step 2 of "Add patient": create the login credentials the patient will
/// use to sign in later, then save everything.
class AdminAddPatientCredentialsScreen extends ConsumerStatefulWidget {
  const AdminAddPatientCredentialsScreen({super.key, required this.patientDetails});

  final Map<String, dynamic> patientDetails;

  @override
  ConsumerState<AdminAddPatientCredentialsScreen> createState() => _AdminAddPatientCredentialsScreenState();
}

class _AdminAddPatientCredentialsScreenState extends ConsumerState<AdminAddPatientCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final details = widget.patientDetails;
      await ref.read(patientRepositoryProvider).createPatientWithCredentials(
            fullName: details['fullName']?.toString() ?? '',
            age: int.tryParse(details['age']?.toString() ?? '') ?? 0,
            phone: details['phone']?.toString() ?? '',
            gender: details['gender']?.toString() ?? '',
            residence: details['residence']?.toString() ?? '',
            email: details['email']?.toString() ?? '',
            emergencyNotes: details['emergencyNotes']?.toString() ?? '',
            allergiesOrNotes: details['allergiesOrNotes']?.toString(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient added. They can now log in with these credentials.')),
      );
      context.goNamed(RouteNames.adminDashboard);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save patient: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add patient')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Create patient login credentials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Fully enter a patient into the Goshen system so that they could login in anytime to manage their treatments',
              style: TextStyle(color: AppColors.muted(context)),
            ),
            const SizedBox(height: 20),
            PasswordFormField(
              controller: _passwordController,
              label: 'Password',
              validator: (value) => (value == null || value.length < 6) ? 'Use at least 6 characters' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save patient'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
