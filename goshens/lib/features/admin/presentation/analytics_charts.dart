import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../data/clinic_analytics.dart';

const _chartPalette = <Color>[
  AppColors.primary,
  AppColors.secondary,
  AppColors.accent,
  AppColors.gold,
  Color(0xFF7C3AED),
  AppColors.warning,
  Color(0xFFEC4899),
  AppColors.info,
];

class AnalyticsDonutChart extends StatelessWidget {
  const AnalyticsDonutChart({super.key, required this.slices, this.size = 168});

  final List<NamedCount> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.count);
    if (total == 0) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text('No data yet', style: TextStyle(color: AppColors.muted(context))),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(slices: slices, total: total),
            child: Center(
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < slices.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _chartPalette[i % _chartPalette.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slices[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink(context),
                          ),
                        ),
                      ),
                      Text(
                        '${slices[i].count}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.total});

  final List<NamedCount> slices;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final sweep = (slices[i].count / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt
        ..color = _chartPalette[i % _chartPalette.length];
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices || oldDelegate.total != total;
  }
}

class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({super.key, required this.days});

  final List<DayCount> days;

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(0, (sum, day) => math.max(sum, day.count));
    final barMax = math.max(maxCount, 1);

    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: day.count / barMax,
                          widthFactor: 0.72,
                          child: Container(
                            decoration: BoxDecoration(
                              color: day.count == 0
                                  ? AppColors.hairline(context)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _weekday(day.day),
                      style: TextStyle(fontSize: 9, color: AppColors.faint(context)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _weekday(DateTime day) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[day.weekday - 1];
  }
}
