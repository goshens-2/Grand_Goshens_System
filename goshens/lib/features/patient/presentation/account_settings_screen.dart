import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../auth/data/auth_repository.dart';
import '../data/profile_repository.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _savingPassword = false;
  bool _savingEmail = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = Supabase.instance.client.auth.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _savingPassword = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _changeEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _savingEmail = true);
    try {
      await ref.read(authRepositoryProvider).updateEmail(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your inbox to confirm the new email address.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          profileAsync.when(
            data: (profile) {
              final avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(profile['avatar_path'] as String?);
              final name = profile['full_name'] as String? ?? 'Your profile';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user?.email ?? 'No email on file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(RouteNames.patientProfileSetup),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit profile'),
              subtitle: Text(user?.email ?? ''),
              onTap: () => context.pushNamed(RouteNames.patientProfileSetup),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Email'),
          Form(
            key: _emailFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Account email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _savingEmail ? null : _changeEmail,
                  child: _savingEmail
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update email'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader('Change password'),
          Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordFormField(
                  controller: _currentPasswordController,
                  label: 'Current password',
                  validator: (value) => value == null || value.isEmpty ? 'Enter your current password' : null,
                ),
                const SizedBox(height: 12),
                PasswordFormField(
                  controller: _newPasswordController,
                  label: 'New password',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a new password';
                    if (value.length < 6) return 'Use at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                PasswordFormField(
                  controller: _confirmPasswordController,
                  label: 'Confirm new password',
                  validator: (value) => value != _newPasswordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _savingPassword ? null : _changePassword,
                  child: _savingPassword
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save new password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
