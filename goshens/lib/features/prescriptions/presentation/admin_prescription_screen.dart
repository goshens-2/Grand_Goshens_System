import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../admin/data/admin_appointment_repository.dart';
import '../../patient/data/clinic_repository.dart';
import '../../patient/data/profile_repository.dart';
import '../data/pdf_service.dart';
import '../data/prescription_repository.dart';

class AdminPrescriptionScreen extends ConsumerStatefulWidget {
  const AdminPrescriptionScreen({super.key, this.patientContext});

  final Map<String, dynamic>? patientContext;

  @override
  ConsumerState<AdminPrescriptionScreen> createState() => _AdminPrescriptionScreenState();
}

class _AdminPrescriptionScreenState extends ConsumerState<AdminPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationsController = TextEditingController();
  final _instructionsController = TextEditingController();

  Map<String, dynamic>? _selectedAppointment;
  bool _isGenerating = false;

  String? get _patientId => widget.patientContext?['patientId'] as String?;
  String get _patientName => widget.patientContext?['patientName'] as String? ?? 'Patient';
  String? get _avatarPath => widget.patientContext?['avatarPath'] as String?;
  List<Map<String, dynamic>> get _patientAppointments {
    final raw = widget.patientContext?['appointments'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  void initState() {
    super.initState();
    final appointments = _patientAppointments;
    if (appointments.isNotEmpty) {
      _selectedAppointment = appointments.first;
    }
  }

  @override
  void dispose() {
    _medicationsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _generatePrescription() async {
    final patientId = _patientId ?? _selectedAppointment?['patient_id'] as String?;
    final patientName = _patientId != null
        ? _patientName
        : (_selectedAppointment?['profiles']?['full_name'] as String? ?? 'Unknown Patient');

    if (!_formKey.currentState!.validate() || patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a patient and complete the prescription fields.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final medications = parseMedicationLines(_medicationsController.text);
      final instructions = _instructionsController.text.trim();
      final clinic = ref.read(clinicSettingsProvider).asData?.value;
      final doctorName = (clinic?['dentist_name'] as String?)?.trim().isNotEmpty == true
          ? clinic!['dentist_name'] as String
          : 'Dr. Goshens';

      final repository = ref.read(prescriptionRepositoryProvider);
      final prescription = await repository.createPrescription(
        patientId: patientId,
        appointmentId: _selectedAppointment?['id'] as String?,
        doctorName: doctorName,
        medications: medications,
        instructions: instructions,
      );

      final pdfUrl = await ref.read(pdfServiceProvider).generateAndUploadPrescriptionPdf(
            prescription,
            patientName,
          );
      if (pdfUrl != null) {
        await repository.updatePrescriptionPdfUrl(prescription.id, pdfUrl);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pdfUrl == null
              ? 'Prescription saved. The PDF could not be uploaded, but the patient was notified.'
              : 'Prescription sent to $patientName.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (widget.patientContext != null) {
        context.pop(true);
        return;
      }
      _medicationsController.clear();
      _instructionsController.clear();
      setState(() => _selectedAppointment = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate prescription: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(clinicSettingsProvider);
    final avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(_avatarPath);
    final lockedToPatient = _patientId != null;

    return Scaffold(
      appBar: AppBar(title: Text(lockedToPatient ? 'Write prescription' : 'Prescriptions')),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lockedToPatient)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl == null
                                    ? Text(
                                        _patientName.isNotEmpty ? _patientName[0].toUpperCase() : 'P',
                                        style: TextStyle(color: AppColors.ink(context), fontWeight: FontWeight.w800),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_patientName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink(context))),
                                    const SizedBox(height: 4),
                                    Text('This script will be sent to the patient immediately.', style: TextStyle(color: AppColors.muted(context))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SectionHeader('Select a visit'),
                    if (!lockedToPatient) ...[
                      const SizedBox(height: 4),
                      FutureBuilder(
                        future: ref.read(adminAppointmentRepositoryProvider).getTodayAppointments(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final appointments = snapshot.data ?? [];
                          if (appointments.isEmpty) {
                            return const EmptyState(
                              icon: Icons.event_busy_outlined,
                              title: 'No visits today',
                              message: 'Open a patient record to write a prescription any time.',
                            );
                          }
                          return DropdownButtonFormField<Map<String, dynamic>>(
                            initialValue: _selectedAppointment,
                            decoration: const InputDecoration(labelText: 'Patient appointment'),
                            items: appointments.map((appt) {
                              final name = appt['profiles']?['full_name'] ?? 'Unknown';
                              final service = appt['services']?['name'] ?? '';
                              return DropdownMenuItem(value: appt, child: Text('$name — $service'));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedAppointment = val),
                            validator: (val) => val == null ? 'Select an appointment' : null,
                          );
                        },
                      ),
                    ] else if (_patientAppointments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionHeader('Link to a visit (optional)'),
                      DropdownButtonFormField<Map<String, dynamic>?>(
                        initialValue: _selectedAppointment,
                        decoration: const InputDecoration(labelText: 'Related appointment'),
                        items: [
                          const DropdownMenuItem<Map<String, dynamic>?>(
                            value: null,
                            child: Text('No linked visit'),
                          ),
                          ..._patientAppointments.map((appt) {
                            final service = appt['services']?['name'] ?? 'Visit';
                            final date = appt['final_start_at'] ?? appt['requested_date'] ?? '';
                            return DropdownMenuItem<Map<String, dynamic>?>(
                              value: appt,
                              child: Text('$service · $date'),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedAppointment = val),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const SectionHeader('Medications'),
                    TextFormField(
                      controller: _medicationsController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'One medication per line',
                        hintText: 'Amoxicillin 500mg — 3 times daily for 5 days',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => parseMedicationLines(value ?? '').isEmpty ? 'Add at least one medication' : null,
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader('Instructions'),
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Usage and aftercare',
                        hintText: 'Take after meals. Avoid hot drinks for 24 hours.',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => value == null || value.trim().length < 4 ? 'Add clear instructions' : null,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _generatePrescription,
                      icon: Icon(Icons.medication_outlined),
                      label: Text('Generate & send'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
