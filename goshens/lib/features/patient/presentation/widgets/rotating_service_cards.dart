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
  const RotatingServiceCards({super.key, required this.services});

  final List<Map<String, dynamic>> services;

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
      _fadeController.forward(from: 0);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_pairs.length <= 1) return;
    _timer = Timer.periodic(kServiceCardRotateInterval, (_) {
      if (!mounted) return;
      _fadeController.forward(from: 0);
      setState(() => _pairIndex = (_pairIndex + 1) % _pairs.length);
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
    if (widget.services.isEmpty) {
      return Text('No published services yet.', style: TextStyle(color: AppColors.muted(context)));
    }

    final pairs = _pairs;
    final pair = pairs[_pairIndex % pairs.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
          ),
          child: Row(
            children: [
              Expanded(child: _ServiceSquareCard(service: pair[0])),
              const SizedBox(width: 12),
              Expanded(
                child: pair.length > 1
                    ? _ServiceSquareCard(service: pair[1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (pairs.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pairs.length, (index) {
              final selected = index == _pairIndex % pairs.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: selected ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.hairline(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
      ],
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
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.hairline(context)),
                      ),
                      child: imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.medical_services_outlined,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.medical_services_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
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
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      shortServiceDescription(service['description'] as String?),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted(context), height: 1.35, fontSize: 13),
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
