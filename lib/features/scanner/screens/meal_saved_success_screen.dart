import 'dart:async';

import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/features/shell/main_shell_screen.dart';
import 'package:rud_fits_ai/models/saved_meal_log.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class MealSavedSuccessScreen extends StatefulWidget {
  const MealSavedSuccessScreen({super.key, required this.saved});

  final SavedMealLog saved;

  @override
  State<MealSavedSuccessScreen> createState() => _MealSavedSuccessScreenState();
}

enum _SuccessStage { processing, completed }

class _MealSavedSuccessScreenState extends State<MealSavedSuccessScreen>
    with TickerProviderStateMixin {
  static const _processingMessages = [
    'Salvando sua refeição',
    'Atualizando calorias e macros',
    'Preparando seu resumo',
  ];

  late final AnimationController _pulseController;
  late final AnimationController _successController;
  late final Animation<double> _successScale;
  Timer? _messageTimer;
  _SuccessStage _stage = _SuccessStage.processing;
  int _messageIndex = 0;

  MealType get _mealType => MealType.fromApiValue(widget.saved.mealType);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _successController = AnimationController(
      vsync: this,
      duration: MotionTokens.medium,
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.fastOutSlowIn,
    );
    _startSequence();
  }

  Future<void> _startSequence() async {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      if (!mounted || _stage == _SuccessStage.completed) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _processingMessages.length;
      });
    });

    await Future<void>.delayed(const Duration(milliseconds: 1150));
    if (!mounted) return;

    setState(() => _stage = _SuccessStage.completed);
    _messageTimer?.cancel();
    _pulseController.stop();
    _successController.forward(from: 0);
    await AppHaptics.success();

    await Future<void>.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppTransitions.fade(page: const MainShellScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseController,
                  _successController,
                ]),
                builder: (context, child) {
                  final pulse = _stage == _SuccessStage.processing
                      ? 1 + (_pulseController.value * 0.08)
                      : 1 + (_successController.value * 0.12);
                  final haloColor = _stage == _SuccessStage.completed
                      ? AppColors.primaryGreen
                      : AppColors.aiBlue;

                  return Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            haloColor.withValues(alpha: 0.22),
                            haloColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Transform.translate(
                offset: const Offset(0, -156),
                child: Center(
                  child: ScaleTransition(
                    scale: _stage == _SuccessStage.completed
                        ? _successScale
                        : const AlwaysStoppedAnimation(1),
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card,
                        border: Border.all(
                          color:
                              (_stage == _SuccessStage.completed
                                      ? AppColors.primaryGreen
                                      : AppColors.aiBlue)
                                  .withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_stage == _SuccessStage.completed
                                        ? AppColors.primaryGreen
                                        : AppColors.aiBlue)
                                    .withValues(alpha: 0.24),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: MotionTokens.medium,
                          switchInCurve: MotionTokens.fastOutSlowIn,
                          switchOutCurve: MotionTokens.inOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: _stage == _SuccessStage.completed
                              ? const Icon(
                                  AppIcons.check,
                                  key: ValueKey('check'),
                                  size: 54,
                                  color: AppColors.primaryGreen,
                                )
                              : const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 42,
                                  height: 42,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.2,
                                    color: AppColors.aiBlue,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -118),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: MotionTokens.medium,
                      child: Text(
                        _stage == _SuccessStage.completed
                            ? 'Refeição registrada!'
                            : _processingMessages[_messageIndex],
                        key: ValueKey('${_stage.name}-title-$_messageIndex'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: MotionTokens.medium,
                      child: Text(
                        _stage == _SuccessStage.completed
                            ? 'Tudo certo. Sua refeição já entrou no resumo do dia.'
                            : 'Estamos organizando os detalhes finais para deixar tudo salvo certinho.',
                        key: ValueKey('${_stage.name}-subtitle'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSlide(
                      offset: _stage == _SuccessStage.completed
                          ? Offset.zero
                          : const Offset(0, 0.08),
                      duration: MotionTokens.slow,
                      curve: MotionTokens.fastOutSlowIn,
                      child: AnimatedOpacity(
                        opacity: _stage == _SuccessStage.completed ? 1 : 0.45,
                        duration: MotionTokens.slow,
                        child: _SavedMealSummaryCard(
                          saved: widget.saved,
                          mealType: _mealType,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _stage == _SuccessStage.completed ? 1 : 0.72,
                duration: MotionTokens.medium,
                child: Text(
                  _stage == _SuccessStage.completed
                      ? 'Voltando para o app...'
                      : 'Quase pronto...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedMealSummaryCard extends StatelessWidget {
  const _SavedMealSummaryCard({required this.saved, required this.mealType});

  final SavedMealLog saved;
  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryPill(
            icon: AppIcons.checkCircle,
            label: mealType.labelPt,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(height: 14),
          Text(
            saved.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resumo nutricional atualizado com sucesso.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SuccessMetricTile(
                  label: 'Calorias',
                  value: '${saved.totalCalories}',
                  suffix: 'kcal',
                  icon: AppIcons.flame,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SuccessMetricTile(
                  label: 'Proteína',
                  value: _formatMacro(saved.totalProtein),
                  suffix: 'g',
                  icon: AppIcons.barbell,
                  color: AppColors.aiBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SuccessMetricTile(
                  label: 'Carbo',
                  value: _formatMacro(saved.totalCarbs),
                  suffix: 'g',
                  icon: AppIcons.grains,
                  color: AppColors.lightGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SuccessMetricTile(
                  label: 'Gordura',
                  value: _formatMacro(saved.totalFat),
                  suffix: 'g',
                  icon: AppIcons.drop,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessMetricTile extends StatelessWidget {
  const _SuccessMetricTile({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $suffix',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMacro(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
