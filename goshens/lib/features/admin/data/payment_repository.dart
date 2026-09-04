import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records a single payment against a service and keeps a running balance
/// per patient/service so repeat payments reduce the balance until it
/// reaches zero. Prices come from the "Doctor's use only" service pricing
/// screen.
class PaymentRepository {
  PaymentRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Total already paid by [patientId] for [serviceId].
  Future<num> getAmountPaid({required String patientId, required String serviceId}) async {
    final rows = await _supabase
        .from('payments')
        .select('amount_paid')
        .eq('patient_id', patientId)
        .eq('service_id', serviceId);
    num total = 0;
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      total += (row['amount_paid'] as num? ?? 0);
    }
    return total;
  }

  /// Records a payment and returns the remaining balance for that service.
  Future<num> recordPayment({
    required String patientId,
    required String serviceId,
    required String serviceName,
    required num servicePrice,
    required num amountPaid,
  }) async {
    final alreadyPaid = await getAmountPaid(patientId: patientId, serviceId: serviceId);
    final newTotalPaid = alreadyPaid + amountPaid;
    final balance = (servicePrice - newTotalPaid).clamp(0, servicePrice);

    await _supabase.from('payments').insert({
      'patient_id': patientId,
      'service_id': serviceId,
      'service_name': serviceName,
      'service_price': servicePrice,
      'amount_paid': amountPaid,
      'balance_after': balance,
      'created_by': _supabase.auth.currentUser?.id,
    });

    return balance;
  }

  Future<List<Map<String, dynamic>>> getPatientPayments(String patientId) async {
    final response = await _supabase
        .from('payments')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final response = await _supabase
        .from('payments')
        .select('*, profiles(full_name, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(Supabase.instance.client);
});
