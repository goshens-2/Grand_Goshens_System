import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../data/profile_repository.dart';

class PatientProfileSetupScreen extends ConsumerStatefulWidget {
  const PatientProfileSetupScreen({super.key});

  @override
  ConsumerState<PatientProfileSetupScreen> createState() => _PatientProfileSetupScreenState();
}

class _PatientProfileSetupScreenState extends ConsumerState<PatientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _allergiesController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _avatarUrl;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getProfile();
      if (mounted) {
        setState(() {
          _nameController.text = profile['full_name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _dobController.text = profile['date_of_birth'] ?? '';
          _gender = profile['gender'] as String?;
          _genderController.text = _gender ?? '';
          _addressController.text = profile['address'] ?? '';
          _emergencyController.text = profile['emergency_contact'] ?? '';
          _allergiesController.text = profile['allergies_or_notes'] ?? '';
          _avatarUrl = repo.publicAvatarUrl(profile['avatar_path'] as String?);
        });
      }
    } catch (_) {
      // Ignore if no profile exists yet
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await image.readAsBytes();
      final path = await ref.read(profileRepositoryProvider).uploadAvatar(
            bytes,
            contentType: image.mimeType ?? 'image/jpeg',
          );
      if (!mounted) return;
      setState(() {
        _avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(path);
      });
      ref.invalidate(currentProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not upload photo. Run fix_avatars_storage.sql in Supabase if this continues.\n$e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            dateOfBirth: _dobController.text.isEmpty ? null : _dobController.text,
            gender: _gender,
            address: _addressController.text.trim(),
            emergencyContact: _emergencyController.text.trim(),
            allergiesOrNotes: _allergiesController.text.trim(),
          );
      ref.invalidate(currentProfileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(RouteNames.patientHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Keep your details up to date so the clinic can care for you properly.',
                  style: TextStyle(color: AppColors.muted(context)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                        child: _isUploadingPhoto
                            ? const CircularProgressIndicator()
                            : _avatarUrl == null
                                ? Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the camera icon to upload a profile photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number *'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(_gender ?? 'none'),
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender (Optional)'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _gender = val;
                      _genderController.text = val ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Home Area / Address (Optional)'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyController,
                  decoration: const InputDecoration(labelText: 'Emergency Contact (Optional)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Allergies or Health Notes (Optional)',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
