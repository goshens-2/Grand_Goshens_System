import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';

/// Step 1 of "Add patient": the patient's details. Step 2 (login
/// credentials) is shown after this form is submitted.
class AdminAddPatientDetailsScreen extends StatefulWidget {
  const AdminAddPatientDetailsScreen({super.key});

  @override
  State<AdminAddPatientDetailsScreen> createState() => _AdminAddPatientDetailsScreenState();
}

class _AdminAddPatientDetailsScreenState extends State<AdminAddPatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _residenceController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _allergiesController = TextEditingController();
  String _gender = 'Female';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _residenceController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    context.pushNamed(
      RouteNames.adminAddPatientCredentials,
      extra: {
        'fullName': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'residence': _residenceController.text.trim(),
        'email': _emailController.text.trim(),
        'emergencyNotes': _emergencyController.text.trim(),
        'allergiesOrNotes': _allergiesController.text.trim(),
      },
    );
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
              'Patient details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
              validator: (value) {
                final age = int.tryParse(value ?? '');
                if (age == null || age <= 0) return 'Enter a valid age';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _gender = value ?? _gender),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _residenceController,
              decoration: const InputDecoration(labelText: 'Place of residence'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Residence is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email account'),
              validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emergencyController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Emergency notes'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Emergency notes are required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _allergiesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Allergies / health notes (optional)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _continue,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
