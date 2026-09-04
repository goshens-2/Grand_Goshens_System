import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/doctor_lock_repository.dart';

/// Gate used by "Doctor's use only" and by "Payment records". The first time
/// it is opened the doctor creates + confirms a passcode which is saved in
/// the database; every time after that the same passcode must be entered.
Future<bool> unlockDoctorFeature(BuildContext context, WidgetRef ref) async {
  final repository = ref.read(doctorLockRepositoryProvider);
  final hasPasscode = await repository.hasPasscode();
  if (!context.mounted) return false;

  if (!hasPasscode) {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _CreatePasscodeDialog(repository: repository),
        ) ??
        false;
  }

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _EnterPasscodeDialog(repository: repository),
      ) ??
      false;
}

class _CreatePasscodeDialog extends StatefulWidget {
  const _CreatePasscodeDialog({required this.repository});

  final DoctorLockRepository repository;

  @override
  State<_CreatePasscodeDialog> createState() => _CreatePasscodeDialogState();
}

class _CreatePasscodeDialogState extends State<_CreatePasscodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passcodeController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passcodeController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passcodeController.text != _confirmController.text) {
      setState(() => _error = 'Passcodes do not match');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.createPasscode(_passcodeController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save passcode: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create a passcode"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This passcode protects Doctor\'s use only. Set it once here.',
              style: TextStyle(color: AppColors.muted(context)),
            ),
            const SizedBox(height: 16),
            PasswordFormField(
              controller: _passcodeController,
              label: 'New passcode',
              validator: (value) =>
                  (value == null || value.trim().length < 4) ? 'At least 4 characters' : null,
            ),
            const SizedBox(height: 12),
            PasswordFormField(
              controller: _confirmController,
              label: 'Confirm passcode',
              validator: (value) => (value == null || value.isEmpty) ? 'Confirm your passcode' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save passcode'),
        ),
      ],
    );
  }
}

class _EnterPasscodeDialog extends StatefulWidget {
  const _EnterPasscodeDialog({required this.repository});

  final DoctorLockRepository repository;

  @override
  State<_EnterPasscodeDialog> createState() => _EnterPasscodeDialogState();
}

class _EnterPasscodeDialogState extends State<_EnterPasscodeDialog> {
  final _controller = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await widget.repository.verifyPasscode(_controller.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _checking = false;
        _error = 'Incorrect passcode';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter passcode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PasswordFormField(controller: _controller, label: 'Passcode', onFieldSubmitted: (_) => _submit()),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: _checking
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Unlock'),
        ),
      ],
    );
  }
}
