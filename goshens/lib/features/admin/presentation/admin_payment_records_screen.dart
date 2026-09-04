import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/patient_repository.dart';
import '../data/payment_repository.dart';

enum _PaymentsFilter { all, today, lastMonth }

/// Sensitive area: passcode-gated (checked before this screen is reached).
/// Lists patients with search + a simple filter, and shows every payment
/// made by the selected patient.
class AdminPaymentRecordsScreen extends ConsumerStatefulWidget {
  const AdminPaymentRecordsScreen({super.key});

  @override
  ConsumerState<AdminPaymentRecordsScreen> createState() => _AdminPaymentRecordsScreenState();
}

class _AdminPaymentRecordsScreenState extends ConsumerState<AdminPaymentRecordsScreen> {
  var _query = '';
  var _filter = _PaymentsFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment records')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(patientRepositoryProvider).getPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final patients = (snapshot.data ?? [])
              .where((p) => matchesQuery(_query, [p['full_name'], p['phone'], p['email']]))
              .toList();

          return Column(
            children: [
              ListSearchBar(
                hint: 'Search patients',
                onChanged: (value) => setState(() => _query = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('All'), selected: _filter == _PaymentsFilter.all, onSelected: (_) => setState(() => _filter = _PaymentsFilter.all)),
                    ChoiceChip(label: const Text('Today'), selected: _filter == _PaymentsFilter.today, onSelected: (_) => setState(() => _filter = _PaymentsFilter.today)),
                    ChoiceChip(label: const Text('Last month'), selected: _filter == _PaymentsFilter.lastMonth, onSelected: (_) => setState(() => _filter = _PaymentsFilter.lastMonth)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: patients.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, title: 'No matching patients')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          final name = patient['full_name']?.toString() ?? 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text(patient['phone']?.toString() ?? 'No phone'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openPayments(context, patient['id'] as String, name),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPayments(BuildContext context, String patientId, String patientName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(paymentRepositoryProvider).getPatientPayments(patientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var payments = snapshot.data ?? [];
                if (_filter != _PaymentsFilter.all) {
                  final now = DateTime.now();
                  payments = payments.where((p) {
                    final createdAt = DateTime.tryParse(p['created_at']?.toString() ?? '');
                    if (createdAt == null) return false;
                    if (_filter == _PaymentsFilter.today) {
                      return createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
                    }
                    return now.difference(createdAt) <= const Duration(days: 31);
                  }).toList();
                }

                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payments.isEmpty ? 'No payment records yet' : '${payments.length} payment record(s)',
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                    const SizedBox(height: 16),
                    if (payments.isEmpty)
                      const EmptyState(icon: Icons.payments_outlined, title: 'No payments recorded')
                    else
                      for (final payment in payments) _PaymentTile(payment: payment),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(payment['created_at']?.toString() ?? '');
    final date = createdAt == null ? '' : DateFormat('d MMM yyyy, h:mm a').format(createdAt.toLocal());
    final serviceName = payment['service_name']?.toString() ?? 'Service';
    final amountPaid = (payment['amount_paid'] as num?) ?? 0;
    final balance = (payment['balance_after'] as num?) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context))),
            const SizedBox(height: 4),
            Text(date, style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
            const SizedBox(height: 8),
            Text('Paid: $amountPaid', style: TextStyle(color: AppColors.ink(context))),
            Text(
              balance <= 0 ? 'Balance: fully paid' : 'Balance remaining: $balance',
              style: TextStyle(color: balance <= 0 ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
