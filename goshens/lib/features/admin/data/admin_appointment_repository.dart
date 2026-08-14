import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'admin_appointment_repository.g.dart';

class AdminAppointmentRepository {
  final SupabaseClient _supabase;

  AdminAppointmentRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final response = await _supabase
        .from('appointments')
        .select('*, profiles!appointments_patient_id_fkey(full_name), services(name, estimated_duration_minutes)')
        .eq('status', 'pending_review')
        .order('requested_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    final response = await _supabase
        .from('appointments')
        .select('*, profiles!appointments_patient_id_fkey(full_name), services(name)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getTodayAppointments() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _supabase
        .from('appointments')
        .select('*, profiles!appointments_patient_id_fkey(full_name, phone), services(name)')
        .inFilter('status', ['approved', 'scheduled', 'checked_in', 'in_consultation'])
        .gte('final_start_at', startOfDay.toIso8601String())
        .lt('final_start_at', endOfDay.toIso8601String())
        .order('final_start_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> scheduleAppointment({
    required String appointmentId,
    required String patientId,
    required DateTime startAt,
    required DateTime endAt,
    required String confirmationNote,
  }) async {
    try {
      await _supabase.rpc(
        'schedule_appointment',
        params: {
          'p_appointment_id': appointmentId,
          'p_start': startAt.toUtc().toIso8601String(),
          'p_end': endAt.toUtc().toIso8601String(),
          'p_note': confirmationNote,
        },
      );
      return;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('overlap') || (e.code ?? '').contains('23P01')) {
        throw Exception('That date and time overlaps another appointment. Choose a different slot.');
      }
      if (message.contains('could not find the function') || message.contains('does not exist')) {
        // Fall through to the direct update used before the RPC existed.
      } else {
        throw Exception(e.message);
      }
    }

    try {
      await _supabase.from('appointments').update({
        'status': 'scheduled',
        'requested_date':
            '${startAt.year.toString().padLeft(4, '0')}-${startAt.month.toString().padLeft(2, '0')}-${startAt.day.toString().padLeft(2, '0')}',
        'final_start_at': startAt.toUtc().toIso8601String(),
        'final_end_at': endAt.toUtc().toIso8601String(),
        'dentist_response': confirmationNote,
        'pre_visit_instructions':
            'Please arrive 10 minutes early and bring your appointment QR card for check-in.',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', appointmentId);
    } on PostgrestException catch (e) {
      if ((e.code ?? '').contains('23P01') ||
          e.message.toLowerCase().contains('overlap') ||
          e.message.contains('no_overlapping')) {
        throw Exception('That date and time overlaps another appointment. Choose a different slot.');
      }
      throw Exception(e.message);
    }

    await _ensureQrToken(appointmentId);

    try {
      await _supabase.from('appointment_status_history').insert({
        'appointment_id': appointmentId,
        'changed_by_id': _supabase.auth.currentUser?.id,
        'old_status': 'pending_review',
        'new_status': 'scheduled',
        'note': confirmationNote,
      });
    } catch (_) {
      // History is helpful but not required for the patient QR card.
    }

    await _supabase.from('notifications').insert({
      'recipient_id': patientId,
      'type': 'appointment_confirmed',
      'title': 'Appointment confirmed',
      'body': '$confirmationNote Open your appointment card to view your QR code for check-in.',
      'related_appointment_id': appointmentId,
    });
  }

  Future<void> updateAppointmentStatus(
    String id,
    String status, {
    String? finalStartAt,
    String? finalEndAt,
    String? note,
    required String patientId,
  }) async {
    if (status == 'scheduled' && finalStartAt != null) {
      await scheduleAppointment(
        appointmentId: id,
        patientId: patientId,
        startAt: DateTime.parse(finalStartAt).toLocal(),
        endAt: finalEndAt != null
            ? DateTime.parse(finalEndAt).toLocal()
            : DateTime.parse(finalStartAt).toLocal().add(const Duration(minutes: 30)),
        confirmationNote: note ?? 'Your appointment has been confirmed.',
      );
      return;
    }

    final updates = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (finalStartAt != null) updates['final_start_at'] = finalStartAt;
    if (finalEndAt != null) updates['final_end_at'] = finalEndAt;
    if (note != null && status != 'completed' && status != 'checked_in') {
      updates['dentist_response'] = note;
    }
    if (status == 'checked_in') {
      updates['check_in_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (status == 'completed') {
      updates['completed_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (status == 'rejected' && note != null) {
      updates['rejection_reason'] = note;
      updates['dentist_response'] = note;
    }

    await _supabase.from('appointments').update(updates).eq('id', id);

    if (status == 'checked_in') {
      await _supabase.from('appointment_qr_tokens').update({
        'used_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('appointment_id', id);
    }

    if (status != 'checked_in' && status != 'completed' && status != 'in_consultation') {
      await _supabase.from('notifications').insert({
        'recipient_id': patientId,
        'type': 'appointment_update',
        'title': 'Appointment ${status.replaceAll('_', ' ')}',
        'body': note ??
            'Your appointment status has been updated to ${status.replaceAll('_', ' ')}.',
        'related_appointment_id': id,
      });
    }
  }

  Future<String> _ensureQrToken(String appointmentId) async {
    final existing = await _supabase
        .from('appointment_qr_tokens')
        .select('secure_token')
        .eq('appointment_id', appointmentId)
        .maybeSingle();
    final existingToken = existing?['secure_token'] as String?;
    if (existingToken != null && existingToken.isNotEmpty) {
      return existingToken;
    }

    final token = const Uuid().v4().replaceAll('-', '');
    try {
      await _supabase.from('appointment_qr_tokens').upsert(
        {
          'appointment_id': appointmentId,
          'secure_token': token,
        },
        onConflict: 'appointment_id',
      );
      return token;
    } catch (_) {
      final retry = await _supabase
          .from('appointment_qr_tokens')
          .select('secure_token')
          .eq('appointment_id', appointmentId)
          .maybeSingle();
      final retryToken = retry?['secure_token'] as String?;
      if (retryToken != null && retryToken.isNotEmpty) {
        return retryToken;
      }
      throw Exception(
        'The appointment was scheduled, but the QR card could not be created. Try approving again.',
      );
    }
  }

  Future<Map<String, dynamic>?> getAppointmentByQrToken(String token) async {
    final response = await _supabase
        .from('appointment_qr_tokens')
        .select(
          '*, appointments(*, profiles!appointments_patient_id_fkey(full_name, phone), services(name))',
        )
        .eq('secure_token', token)
        .maybeSingle();

    if (response == null || response['appointments'] == null) {
      return null;
    }

    return response['appointments'] as Map<String, dynamic>;
  }
}

@riverpod
AdminAppointmentRepository adminAppointmentRepository(AdminAppointmentRepositoryRef ref) {
  return AdminAppointmentRepository(Supabase.instance.client);
}
