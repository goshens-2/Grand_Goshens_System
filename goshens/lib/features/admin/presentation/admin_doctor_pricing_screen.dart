import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_ui.dart';
import '../data/admin_service_repository.dart';
import 'doctor_lock_gate.dart';

/// "Doctor's use only": passcode-protected service pricing. Prices saved
/// here are used later to calculate the remaining balance during QR-scan
/// payments.
class DoctorPricingScreen extends ConsumerStatefulWidget {
  const DoctorPricingScreen({super.key});

  @override
  ConsumerState<DoctorPricingScreen> createState() => _DoctorPricingScreenState();
}

class _DoctorPricingScreenState extends ConsumerState<DoctorPricingScreen> {
  bool? _unlocked;
  List<Map<String, dynamic>> _services = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _unlock() async {
    final ok = await unlockDoctorFeature(context, ref);
    if (!mounted) return;
    if (!ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _unlocked = true);
    await _loadServices();
  }

  Future<void> _loadServices() async {
    final services = await ref.read(adminServiceRepositoryProvider).getAllServices();
    if (!mounted) return;
    setState(() {
      _services = services;
      for (final service in services) {
        final id = service['id'] as String;
        final price = service['price'];
        _controllers.putIfAbsent(id, () => TextEditingController());
        _controllers[id]!.text = price == null ? '0' : price.toString();
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminServiceRepositoryProvider);
      for (final service in _services) {
        final id = service['id'] as String;
        final price = num.tryParse(_controllers[id]?.text.trim() ?? '') ?? 0;
        await repo.updateServicePrice(id: id, price: price);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service prices saved'), backgroundColor: AppColors.success),
        );
        await _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save prices: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked != true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Doctor's use only")),
      body: _services.isEmpty
          ? const EmptyState(
              icon: Icons.medical_services_outlined,
              title: 'No services yet',
              message: 'Add services first, then set their prices here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                Text(
                  'Set a price for every service. Updated services appear here automatically.',
                  style: TextStyle(color: AppColors.muted(context)),
                ),
                const SizedBox(height: 16),
                for (final service in _services)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.hairline(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name']?.toString() ?? 'Service',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink(context)),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _controllers[service['id']],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: 'UGX ',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _services.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                  onPressed: _saving ? null : _saveAll,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save all changes'),
                ),
              ),
            ),
    );
  }
}
