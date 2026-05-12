import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class AnalyzingOverlay extends StatefulWidget {
  const AnalyzingOverlay({super.key});

  @override
  State<AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<AnalyzingOverlay>
    with TickerProviderStateMixin {
  static const _steps = [
    'Detectando alimentos...',
    'Estimando quantidades...',
    'Calculando calorias e macros...',
  ];

  int _currentStep = 0;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _cycleSteps();
  }

  Future<void> _cycleSteps() async {
    for (var i = 1; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() => _currentStep = i);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final scale = 0.92 + (_pulse.value * 0.12);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen
                                    .withValues(alpha: 0.25 + _pulse.value * 0.25),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.primaryGreen,
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: MotionTokens.medium,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _steps[_currentStep],
                      key: ValueKey(_currentStep),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A IA está trabalhando na sua refeição',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_steps.length, (i) {
                      final active = i <= _currentStep;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AnimatedContainer(
                          duration: MotionTokens.normal,
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: active
                                ? AppColors.primaryGreen
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      );
                    }),
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
