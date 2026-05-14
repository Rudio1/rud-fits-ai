import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class MealMacroChartCard extends StatelessWidget {
  const MealMacroChartCard({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;

  static const _pColor = AppColors.aiBlue;
  static const _cColor = AppColors.lightGreen;
  static const _fColor = AppColors.warning;

  double get _totalG => protein + carbs + fat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalG;
    final hasData = total > 0.0001;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(168, 168),
                  painter: _MacroDonutPainter(
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    proteinColor: _pColor,
                    carbsColor: _cColor,
                    fatColor: _fColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasData ? '${total.toStringAsFixed(0)} g' : '—',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? 'macros totais' : 'sem gramas registradas',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _LegendRow(
            label: 'Proteína',
            value: protein,
            fractionDigits: 0,
            color: _pColor,
            icon: AppIcons.barbell,
            total: total,
            hasData: hasData,
          ),
          const SizedBox(height: 8),
          _LegendRow(
            label: 'Carboidratos',
            value: carbs,
            fractionDigits: 1,
            color: _cColor,
            icon: AppIcons.grains,
            total: total,
            hasData: hasData,
          ),
          const SizedBox(height: 8),
          _LegendRow(
            label: 'Gorduras',
            value: fat,
            fractionDigits: 1,
            color: _fColor,
            icon: AppIcons.drop,
            total: total,
            hasData: hasData,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.value,
    required this.fractionDigits,
    required this.color,
    required this.icon,
    required this.total,
    required this.hasData,
  });

  final String label;
  final double value;
  final int fractionDigits;
  final Color color;
  final IconData icon;
  final double total;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = hasData && total > 0 ? (100 * value / total).clamp(0.0, 100.0) : 0.0;
    final pctLabel = hasData && total > 0 ? '${pct.round()}%' : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: color.withValues(alpha: 0.95)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            pctLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${value.toStringAsFixed(fractionDigits)} g',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroDonutPainter extends CustomPainter {
  _MacroDonutPainter({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
  });

  final double protein;
  final double carbs;
  final double fat;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide / 2;
    final stroke = outerR * 0.2;
    final r = outerR - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: r);

    final total = protein + carbs + fat;
    if (total <= 0.0001) {
      final paint = Paint()
        ..color = AppColors.borderDefault
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * 0.998, false, paint);
      return;
    }

    var start = -math.pi / 2;
    void strokeSeg(double grams, Color color) {
      if (grams <= 0) return;
      final sweep = math.max(2 * math.pi * (grams / total), 0.02);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    strokeSeg(protein, proteinColor);
    strokeSeg(carbs, carbsColor);
    strokeSeg(fat, fatColor);
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter oldDelegate) {
    return oldDelegate.protein != protein ||
        oldDelegate.carbs != carbs ||
        oldDelegate.fat != fat;
  }
}
