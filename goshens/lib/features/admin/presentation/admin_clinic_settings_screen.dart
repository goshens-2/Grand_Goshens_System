import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/clinic_settings_repository.dart';
import '../../patient/data/clinic_repository.dart';

class AdminClinicSettingsScreen extends ConsumerStatefulWidget {
  const AdminClinicSettingsScreen({super.key});

  @override
  ConsumerState<AdminClinicSettingsScreen> createState() => _AdminClinicSettingsScreenState();
}

class _AdminClinicSettingsScreenState extends ConsumerState<AdminClinicSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _clinicNameController;
  late TextEditingController _taglineController;
  late TextEditingController _addressController;
  late TextEditingController _dentistNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String? _settingsId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _clinicNameController = TextEditingController();
    _taglineController = TextEditingController();
    _addressController = TextEditingController();
    _dentistNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final repo = ref.read(clinicSettingsRepositoryProvider);
      final settings = await repo.getSettings();
      
      setState(() {
        _settingsId = settings['id'];
        _clinicNameController.text = settings['clinic_name'] ?? '';
        _taglineController.text = settings['tagline'] ?? '';
        _addressController.text = settings['address'] ?? '';
        _dentistNameController.text = settings['dentist_name'] ?? '';
        _phoneController.text = settings['phone'] ?? '';
        _emailController.text = settings['email'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _settingsId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final updates = {
        'clinic_name': _clinicNameController.text.trim(),
        'tagline': _taglineController.text.trim(),
        'address': _addressController.text.trim(),
        'dentist_name': _dentistNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };
      
      await ref.read(clinicSettingsRepositoryProvider).updateSettings(_settingsId!, updates);
      ref.invalidate(clinicSettingsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _dentistNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic settings'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: CircularProgressIndicator(color: Colors.white)))
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: GoshensLogo(size: 72, glow: true)),
              const SizedBox(height: 20),
              const SectionHeader('Clinic profile'),
              TextFormField(
                controller: _clinicNameController,
                decoration: const InputDecoration(labelText: 'Clinic Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taglineController,
                decoration: const InputDecoration(labelText: 'Tagline'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dentistNameController,
                decoration: const InputDecoration(labelText: 'Primary Dentist Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Clinic Address'),
                maxLines: 2,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
