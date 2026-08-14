import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../data/appointment_repository.dart';
import '../data/availability_repository.dart';
import '../data/service_repository.dart';

class PatientBookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  final String serviceName;

  const PatientBookingScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  ConsumerState<PatientBookingScreen> createState() => _PatientBookingScreenState();
}

class _PatientBookingScreenState extends ConsumerState<PatientBookingScreen> {
  DateTime? _selectedDate;
  String? _selectedPeriod;
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (_selectedDate == null || _selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time period')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String targetServiceId = widget.serviceId;
      if (targetServiceId.isEmpty) {
        final services = await ref.read(serviceRepositoryProvider).getPublishedServices();
        if (services.isNotEmpty) {
          targetServiceId = services.first['id'];
        }
      }

      await ref.read(appointmentRepositoryProvider).requestAppointment(
            serviceId: targetServiceId,
            requestedDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
            preferredPeriod: _selectedPeriod!,
            patientNote: _noteController.text.trim(),
          );

      if (mounted) {
        // Show success and pop
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Request Submitted'),
            content: Text(
                'Your appointment request has been submitted. The dentist will review it and set the final time.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.pop(); // Go back to services
                },
                child: Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePeriodsAsync = ref.watch(activePeriodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Request appointment'),
      ),
      body: activePeriodsAsync.when(
        data: (periods) {
          // Compute available days
          final availableDays = periods.map((p) => p['day_of_week'] as int).toSet();

          // Compute available periods for the selected date
          List<String> availablePeriodsForSelectedDate = [];
          if (_selectedDate != null) {
            // DateTime weekday: 1 = Monday, 7 = Sunday
            final dayOfWeek = _selectedDate!.weekday;
            availablePeriodsForSelectedDate = periods
                .where((p) => p['day_of_week'] == dayOfWeek)
                .map((p) => p['period_name'] as String)
                .toSet()
                .toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Service: ${widget.serviceName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Date selection
                Text('1. Select Preferred Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      selectableDayPredicate: (day) {
                        return availableDays.contains(day.weekday);
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedPeriod = null; // Reset period
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Tap to select date'
                              : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null ? Colors.grey : AppColors.ink(context),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Period selection
                Text('2. Select Preferred Time Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'The exact time will be confirmed by the dentist.',
                  style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_selectedDate == null)
                  Text('Please select a date first.', style: TextStyle(color: AppColors.warning))
                else if (availablePeriodsForSelectedDate.isEmpty)
                  Text('No periods available for this date.', style: TextStyle(color: AppColors.error))
                else
                  Wrap(
                    spacing: 12,
                    children: availablePeriodsForSelectedDate.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return ChoiceChip(
                        label: Text(period),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPeriod = selected ? period : null;
                          });
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.ink(context)),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 32),

                // Note
                Text('3. Add a Note (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your dental issue or any special requests...',
                  ),
                  maxLines: 4,
                ),

                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Text('Submit Request'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
