import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/prescription.dart';

part 'prescription_repository.g.dart';

class PrescriptionRepository {
  final SupabaseClient _supabase;

  PrescriptionRepository(this._supabase);

  Future<List<Prescription>> getPatientPrescriptions(String patientId) async {
    final response = await _supabase
        .from('prescriptions')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map(_mapPrescription)
        .toList();
  }

  Future<Prescription> createPrescription({
    required String patientId,
    String? appointmentId,
    required String doctorName,
    required List<String> medications,
    required String instructions,
    String? pdfUrl,
  }) async {
    final adminId = _supabase.auth.currentUser?.id;
    final response = await _supabase.from('prescriptions').insert({
      'patient_id': patientId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (adminId != null) 'issued_by_admin_id': adminId,
      'doctor_name': doctorName,
      'medications': medications,
      'instructions': instructions,
      if (pdfUrl case final url?) 'pdf_url': url,
    }).select().single();

    await _supabase.from('notifications').insert({
      'recipient_id': patientId,
      'type': 'prescription_ready',
      'title': 'New Prescription',
      'body': 'A new prescription has been generated for you by $doctorName.',
      if (appointmentId case final id?) 'related_appointment_id': id,
      'related_prescription_id': response['id'],
    });

    return _mapPrescription(Map<String, dynamic>.from(response));
  }

  Future<void> updatePrescriptionPdfUrl(String id, String url) async {
    await _supabase.from('prescriptions').update({'pdf_url': url}).eq('id', id);
  }

  Prescription _mapPrescription(Map<String, dynamic> json) {
    return Prescription.fromJson({
      ...json,
      'doctor_name': json['doctor_name'] ?? 'Dentist',
      'medications': List<dynamic>.from(json['medications'] ?? const []),
      'instructions': json['instructions'] ?? '',
    });
  }
}

List<String> parseMedicationLines(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

@riverpod
PrescriptionRepository prescriptionRepository(PrescriptionRepositoryRef ref) {
  return PrescriptionRepository(Supabase.instance.client);
}
