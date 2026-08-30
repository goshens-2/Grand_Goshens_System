import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../data/service_repository.dart';
import '../../data/service_visuals.dart';

const kServiceCardRotateInterval = Duration(seconds: 8);

class RotatingServiceCards extends ConsumerStatefulWidget {
  const RotatingServiceCards({
    super.key,
    required this.services,
    this.onPairChange,
  });

  final List<Map<String, dynamic>> services;
  final Function(int)? onPairChange;

  @override
  ConsumerState<RotatingServiceCards> createState() => _RotatingServiceCardsState();
}

class _RotatingServiceCardsState extends ConsumerState<RotatingServiceCards> with TickerProviderStateMixin {
  Timer? _timer;
  var _pairIndex = 0;
  late AnimationController _fadeController;

  List<List<Map<String, dynamic>>> get _pairs {
    final pairs = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < widget.services.length; i += 2) {
      pairs.add(widget.services.sublist(i, i + 2 > widget.services.length ? widget.services.length : i + 2));
    }
    return pairs;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant RotatingServiceCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.services.length != widget.services.length) {
      _pairIndex = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_pairs.length <= 1) return;
    _timer = Timer.periodic(kServiceCardRotateInterval, (_) {
      if (!mounted) return;
      _fadeController.forward(from: 0.0);
      setState(() {
        _pairIndex = (_pairIndex + 1) % _pairs.length;
        widget.onPairChange?.call(_pairIndex);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentPair = _pairs[_pairIndex];
    return FadeTransition(
      opacity: _fadeController.drive(Tween<double>(begin: 0.8, end: 1.0)),
      child: Row(
        children: [
          Expanded(
            child: _ServiceSquareCard(service: currentPair[0]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: currentPair.length > 1 ? _ServiceSquareCard(service: currentPair[1]) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ServiceSquareCard extends ConsumerWidget {
  const _ServiceSquareCard({required this.service});

  final Map<String, dynamic> service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePaths = serviceImagePaths(service);
    final imageUrl = ref.read(serviceRepositoryProvider).publicImageUrl(imagePaths.isEmpty ? null : imagePaths.first);

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.pushNamed(
            RouteNames.patientServiceDetail,
            extra: Map<String, dynamic>.from(service),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairline(context)),
              boxShadow: const [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                iconForService(service['icon_name'] as String?),
                                color: AppColors.ink(context),
                                size: 32,
                              ),
                            )
                          : Icon(
                              iconForService(service['icon_name'] as String?),
                              color: AppColors.ink(context),
                              size: 32,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service['name'] as String? ?? 'Service',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(context),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      shortServiceDescription(service['description'] as String?),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted(context), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
