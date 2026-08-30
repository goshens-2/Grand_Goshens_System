import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../../admin/data/admin_appointment_repository.dart';
import '../../patient/data/clinic_repository.dart';
import '../../patient/data/profile_repository.dart';
import '../data/pdf_service.dart';
import '../data/prescription_repository.dart';
import '../domain/prescription.dart';

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
  var _tabIndex = 0;

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

  Future<void> _deletePrescription(String prescriptionId, String patientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription?'),
        content: Text('Are you sure you want to delete this prescription for $patientName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(prescriptionRepositoryProvider).deletePrescription(prescriptionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription deleted'), backgroundColor: AppColors.success),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete prescription: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(clinicSettingsProvider);
    final avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(_avatarPath);
    final lockedToPatient = _patientId != null;

    return DefaultTabController(
      length: lockedToPatient ? 1 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lockedToPatient ? 'Write prescription' : 'Prescriptions'),
          bottom: lockedToPatient
              ? null
              : TabBar(
                  onTap: (index) => setState(() => _tabIndex = index),
                  tabs: const [
                    Tab(text: 'Write new'),
                    Tab(text: 'Existing'),
                  ],
                ),
        ),
        body: _isGenerating
            ? const Center(child: CircularProgressIndicator())
            : lockedToPatient
                ? _buildWriteTab()
                : TabBarView(
                    children: [
                      _buildWriteTab(),
                      _buildExistingTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWriteTab() {
    final avatarUrl = ref.read(profileRepositoryProvider).publicAvatarUrl(_avatarPath);
    final lockedToPatient = _patientId != null;

    return SingleChildScrollView(
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
    );
  }

  Widget _buildExistingTab() {
    return FutureBuilder<List<Prescription>>(
      future: ref.read(prescriptionRepositoryProvider).getPatientPrescriptions(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final prescriptions = snapshot.data ?? [];
        if (prescriptions.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.medication_outlined,
              title: 'No prescriptions yet',
              message: 'Prescriptions will appear here once created.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final pres = prescriptions[index];
            final dateFormat = DateFormat('MMM d, yyyy');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(pres.createdAt.toLocal()),
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink(context)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dr. ${pres.doctorName}',
                                  style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => _deletePrescription(pres.id, 'Patient'),
                            tooltip: 'Delete prescription',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Medications', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink(context))),
                      const SizedBox(height: 6),
                      ...pres.medications.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $m', style: TextStyle(color: AppColors.muted(context))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Instructions', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink(context))),
                      const SizedBox(height: 6),
                      Text(pres.instructions, style: TextStyle(color: AppColors.muted(context), height: 1.45)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
