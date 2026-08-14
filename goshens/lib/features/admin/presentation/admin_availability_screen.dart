import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_availability_repository.dart';

class AdminAvailabilityScreen extends ConsumerStatefulWidget {
  const AdminAvailabilityScreen({super.key});

  @override
  ConsumerState<AdminAvailabilityScreen> createState() => _AdminAvailabilityScreenState();
}

class _AdminAvailabilityScreenState extends ConsumerState<AdminAvailabilityScreen> {
  final Map<int, String> _days = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Availability'),
      ),
      body: FutureBuilder(
        future: ref.read(adminAvailabilityRepositoryProvider).getPeriods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final periods = snapshot.data ?? [];

          // Group by day
          final Map<int, List<Map<String, dynamic>>> grouped = {};
          for (var p in periods) {
            final day = p['day_of_week'] as int;
            grouped.putIfAbsent(day, () => []).add(p);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7, // 7 days of week
            itemBuilder: (context, index) {
              final day = index + 1;
              final dayPeriods = grouped[day] ?? [];
              
              if (dayPeriods.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _days[day]!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink(context),
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...dayPeriods.map((p) {
                        return SwitchListTile(
                          title: Text(p['period_name']),
                          subtitle: Text('${p['start_time']} - ${p['end_time']}'),
                          value: p['is_active'],
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) async {
                            await ref.read(adminAvailabilityRepositoryProvider).togglePeriodActive(p['id'], val);
                            setState(() {});
                          },
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
