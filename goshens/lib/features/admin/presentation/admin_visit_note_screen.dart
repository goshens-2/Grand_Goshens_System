import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/admin_appointment_repository.dart';

class AdminVisitNoteScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;

  const AdminVisitNoteScreen({super.key, required this.appointment});

  @override
  ConsumerState<AdminVisitNoteScreen> createState() => _AdminVisitNoteScreenState();
}

class _AdminVisitNoteScreenState extends ConsumerState<AdminVisitNoteScreen> {
  late TextEditingController _noteController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.appointment['dentist_response'] ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote(String status) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(adminAppointmentRepositoryProvider).updateAppointmentStatus(
        widget.appointment['id'],
        status,
        patientId: widget.appointment['patient_id'],
      );

      try {
        await Supabase.instance.client.from('visit_notes').upsert({
          'appointment_id': widget.appointment['id'],
          'consultation_summary': _noteController.text.trim(),
          'internal_notes': _noteController.text.trim(),
        }, onConflict: 'appointment_id');
      } catch (_) {
        // Visit notes table is optional if the latest SQL has not been applied yet.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit note saved successfully.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.appointment['profiles']?['full_name'] ?? 'Patient';
    final serviceName = widget.appointment['services']?['name'] ?? 'Visit';

    return Scaffold(
      appBar: AppBar(
        title: Text('Visit note'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink(context))),
                    const SizedBox(height: 4),
                    Text(serviceName, style: TextStyle(color: AppColors.muted(context))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader('Clinical notes'),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Findings, treatment provided, and follow-up...',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(
                RouteNames.adminPrescription,
                extra: {
                  'patientId': widget.appointment['patient_id'],
                  'patientName': patientName,
                  'avatarPath': widget.appointment['profiles']?['avatar_path'],
                  'appointments': [widget.appointment],
                },
              ),
              icon: Icon(Icons.medication_outlined),
              label: Text('Write prescription'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _saveNote('completed'),
              child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : Text('Save and mark completed'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : () => _saveNote(widget.appointment['status'] as String? ?? 'scheduled'),
              child: Text('Save note without completing'),
            ),
          ],
        ),
      ),
    );
  }
}
