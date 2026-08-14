import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_appointment_repository.dart';

Future<void> showAppointmentReviewSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> request,
  VoidCallback? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _AppointmentReviewSheet(
        request: request,
        onChanged: onChanged,
      );
    },
  );
}

class _AppointmentReviewSheet extends ConsumerStatefulWidget {
  const _AppointmentReviewSheet({required this.request, this.onChanged});

  final Map<String, dynamic> request;
  final VoidCallback? onChanged;

  @override
  ConsumerState<_AppointmentReviewSheet> createState() => _AppointmentReviewSheetState();
}

class _AppointmentReviewSheetState extends ConsumerState<_AppointmentReviewSheet> {
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.tryParse(widget.request['requested_date']?.toString() ?? '') ?? DateTime.now();
    _date = DateTime(_date.year, _date.month, _date.day);
    final existing = DateTime.tryParse(widget.request['final_start_at']?.toString() ?? '');
    if (existing != null) {
      final local = existing.toLocal();
      _date = DateTime(local.year, local.month, local.day);
      _time = TimeOfDay(hour: local.hour, minute: local.minute);
    }
  }

  DateTime get _start => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _approve() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final durationMinutes = (widget.request['services']?['estimated_duration_minutes'] as num?)?.toInt() ?? 30;
      final start = _start;
      final end = start.add(Duration(minutes: durationMinutes < 10 ? 30 : durationMinutes));
      final confirmationNote =
          'Your appointment is confirmed for ${DateFormat('EEEE, MMM d').format(start)} at ${_time.format(context)}.';

      await ref.read(adminAppointmentRepositoryProvider).scheduleAppointment(
            appointmentId: widget.request['id'] as String,
            patientId: widget.request['patient_id'] as String,
            startAt: start,
            endAt: end,
            confirmationNote: confirmationNote,
          );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment confirmed. The patient now has a notification and QR card.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Review Request', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Patient: ${request['profiles']?['full_name'] ?? 'Unknown'}'),
          Text('Service: ${request['services']?['name'] ?? 'Service'}'),
          Text('Requested: ${request['requested_date']} (${request['preferred_period']})'),
          if ((request['patient_note'] as String?)?.isNotEmpty == true) Text('Note: ${request['patient_note']}'),
          const SizedBox(height: 20),
          Text('Set the visit date and time', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Date'),
            subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_date)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _saving ? null : _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Time'),
            subtitle: Text(_time.format(context)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _saving ? null : _pickTime,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _approve,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Approve & confirm visit'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving
                ? null
                : () async {
                    final reason = await showRejectReasonDialog(context);
                    if (reason == null || reason.trim().isEmpty || !mounted) return;
                    try {
                      await ref.read(adminAppointmentRepositoryProvider).updateAppointmentStatus(
                            request['id'] as String,
                            'rejected',
                            patientId: request['patient_id'] as String,
                            note: reason.trim(),
                          );
                      if (!mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      widget.onChanged?.call();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Request rejected. The patient was given your reason.')),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not reject request: $error'), backgroundColor: AppColors.error),
                      );
                    }
                  },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Future<String?> showRejectReasonDialog(BuildContext context) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Reject appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tell the patient why this request cannot be accepted.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. That date is fully booked. Please request another day.',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.length < 6) return;
              Navigator.pop(dialogContext, text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject with reason'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return reason;
}
