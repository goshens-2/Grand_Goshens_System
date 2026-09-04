import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_service_repository.dart';
import '../data/payment_repository.dart';

/// Shown right after a patient's QR code is scanned and they are checked in.
/// Lets the doctor pick the service being paid for and the amount paid, then
/// shows the remaining balance (using prices set in "Doctor's use only").
Future<void> showQrPaymentDialog(
  BuildContext context,
  WidgetRef ref, {
  required String patientId,
  required String patientName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _QrPaymentSheet(patientId: patientId, patientName: patientName),
  );
}

class _QrPaymentSheet extends ConsumerStatefulWidget {
  const _QrPaymentSheet({required this.patientId, required this.patientName});

  final String patientId;
  final String patientName;

  @override
  ConsumerState<_QrPaymentSheet> createState() => _QrPaymentSheetState();
}

class _QrPaymentSheetState extends ConsumerState<_QrPaymentSheet> {
  final _amountController = TextEditingController();
  Map<String, dynamic>? _selectedService;
  var _saving = false;
  num? _balance;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final service = _selectedService;
    final amount = num.tryParse(_amountController.text.trim());
    if (service == null || amount == null || amount <= 0) {
      setState(() => _error = 'Choose a service and enter a valid amount.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final price = (service['price'] as num?) ?? 0;
      final balance = await ref.read(paymentRepositoryProvider).recordPayment(
            patientId: widget.patientId,
            serviceId: service['id'] as String,
            serviceName: service['name']?.toString() ?? 'Service',
            servicePrice: price,
            amountPaid: amount,
          );
      if (!mounted) return;
      setState(() => _balance = balance);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not record the payment: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payment for ${widget.patientName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(adminServiceRepositoryProvider).getAllServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final services = snapshot.data ?? [];
                return DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: _selectedService,
                  decoration: const InputDecoration(labelText: 'Service'),
                  items: services
                      .map((service) => DropdownMenuItem(
                            value: service,
                            child: Text('${service['name']} — ${service['price'] ?? 0}'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedService = value),
                );
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount paid'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
            if (_balance != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_balance! <= 0 ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _balance! <= 0 ? 'Fully paid. Balance: 0' : 'Remaining balance: $_balance',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _balance! <= 0 ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Record payment'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
