import 'package:flutter/material.dart';

import 'package:rud_fits_ai/models/daily_consumption_summary.dart';
import 'package:rud_fits_ai/models/daily_goals.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class DailyGoalProgressSection extends StatelessWidget {
  const DailyGoalProgressSection({
    super.key,
    required this.goals,
    this.summary,
    this.summaryError,
  });

  final DailyGoals goals;
  final DailyConsumptionSummary? summary;
  final String? summaryError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summaryError != null && summary == null) {
      return Text(
        summaryError!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return _ProgressBody(goals: goals, summary: summary!);
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.goals, required this.summary});

  final DailyGoals goals;
  final DailyConsumptionSummary summary;

  static int _pct(int consumed, int goal) {
    if (goal <= 0) return 0;
    return ((consumed / goal) * 100).round();
  }

  static int _pctD(double consumed, double goal) {
    if (goal <= 0) return 0;
    return ((consumed / goal) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kcalConsumed = summary.totalCalories;
    final kcalGoal = goals.calories;

    final kcalPct = kcalGoal > 0 ? _pct(kcalConsumed, kcalGoal) : 0;
    final kcalRatio = kcalGoal > 0 ? kcalConsumed / kcalGoal : 0.0;
    final barW = kcalGoal > 0 ? kcalRatio.clamp(0.0, 1.0) : 0.0;
    final kcalOver = kcalGoal > 0 && kcalConsumed > kcalGoal;

    final pPct = _pctD(summary.totalProtein, goals.protein.toDouble());
    final cPct = _pctD(summary.totalCarbs, goals.carbs.toDouble());
    final fPct = _pctD(summary.totalFat, goals.fat.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PctBarBlock(
          label: 'Calorias',
          percentText: kcalGoal > 0 ? '$kcalPct%' : '—',
          value: barW,
          filledColor: kcalOver ? AppColors.warning : AppColors.primaryGreen,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          percentStyle: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1,
            color: kcalOver ? AppColors.warning : AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Macros · % da meta',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 8),
        _MacroPctBar(
          label: 'P',
          percent: pPct,
          consumed: summary.totalProtein,
          goal: goals.protein.toDouble(),
          color: AppColors.aiBlue,
          theme: theme,
        ),
        const SizedBox(height: 6),
        _MacroPctBar(
          label: 'C',
          percent: cPct,
          consumed: summary.totalCarbs,
          goal: goals.carbs.toDouble(),
          color: AppColors.warning,
          theme: theme,
        ),
        const SizedBox(height: 6),
        _MacroPctBar(
          label: 'G',
          percent: fPct,
          consumed: summary.totalFat,
          goal: goals.fat.toDouble(),
          color: AppColors.error,
          theme: theme,
        ),
      ],
    );
  }
}

class _PctBarBlock extends StatelessWidget {
  const _PctBarBlock({
    required this.label,
    required this.percentText,
    required this.value,
    required this.filledColor,
    required this.labelStyle,
    required this.percentStyle,
  });

  final String label;
  final String percentText;
  final double value;
  final Color filledColor;
  final TextStyle? labelStyle;
  final TextStyle? percentStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: labelStyle),
            ),
            Text(percentText, style: percentStyle),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.background.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(filledColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroPctBar extends StatelessWidget {
  const _MacroPctBar({
    required this.label,
    required this.percent,
    required this.consumed,
    required this.goal,
    required this.color,
    required this.theme,
  });

  final String label;
  final int percent;
  final double consumed;
  final double goal;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final over = goal > 0 && consumed > goal;
    final pctLabel = goal > 0 ? '$percent%' : '—';
    final fill = over ? AppColors.warning : color;

    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.background.withValues(alpha: 0.55),
                valueColor: AlwaysStoppedAnimation<Color>(fill),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            pctLabel,
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: fill,
            ),
          ),
        ),
      ],
    );
  }
}
