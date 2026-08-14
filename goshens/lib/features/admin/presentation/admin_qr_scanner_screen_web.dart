import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_appointment_repository.dart';

class AdminQrScannerScreen extends ConsumerStatefulWidget {
  const AdminQrScannerScreen({super.key});

  @override
  ConsumerState<AdminQrScannerScreen> createState() => _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends ConsumerState<AdminQrScannerScreen> {
  final TextEditingController _manualTokenController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _manualTokenController.dispose();
    super.dispose();
  }

  Future<void> _checkInWithToken(String rawValue) async {
    if (_isProcessing || rawValue.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final appointment = await ref
          .read(adminAppointmentRepositoryProvider)
          .getAppointmentByQrToken(rawValue.trim());

      if (appointment != null) {
        final appointmentId = appointment['id'];
        final patientId = appointment['patient_id'];

        await ref.read(adminAppointmentRepositoryProvider).updateAppointmentStatus(
              appointmentId,
              'checked_in',
              patientId: patientId,
              note: 'Patient checked in at clinic.',
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient successfully checked in!'),
              backgroundColor: AppColors.primary,
            ),
          );
          context.pop();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR Code. Appointment not found.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking in: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_2, size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              kIsWeb
                  ? 'Camera scanning is unavailable in the browser. Paste the appointment QR token below to check in a patient.'
                  : 'Enter the appointment QR token below to check in a patient.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _manualTokenController,
              decoration: const InputDecoration(
                labelText: 'Appointment QR token',
                hintText: 'Paste secure token from appointment card',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _checkInWithToken(_manualTokenController.text),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Check In Patient'),
            ),
          ],
        ),
      ),
    );
  }
}
