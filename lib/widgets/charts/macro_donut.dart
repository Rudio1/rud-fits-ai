import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/models/daily_goals.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class MacroDonut extends StatefulWidget {
  const MacroDonut({
    super.key,
    required this.goals,
    this.size = 210,
    this.strokeWidth = 22,
    this.animate = true,
  });

  final DailyGoals goals;
  final double size;
  final double strokeWidth;
  final bool animate;

  @override
  State<MacroDonut> createState() => _MacroDonutState();
}

class _MacroDonutState extends State<MacroDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: widget.animate ? 0 : 1,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (widget.animate) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MacroDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goals != widget.goals && widget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCalories(int cal) {
    if (cal >= 1000) {
      return '${cal ~/ 1000}.${(cal % 1000).toString().padLeft(3, '0')}';
    }
    return cal.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _MacroDonutPainter(
                  proteinCal: widget.goals.protein * 4.0,
                  carbsCal: widget.goals.carbs * 4.0,
                  fatCal: widget.goals.fat * 9.0,
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatCalories(widget.goals.calories),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'kcal / dia',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MacroLegend extends StatelessWidget {
  const MacroLegend({super.key, required this.goals});

  final DailyGoals goals;

  @override
  Widget build(BuildContext context) {
    final totalCal = goals.protein * 4 + goals.carbs * 4 + goals.fat * 9;
    String pct(int cal) =>
        totalCal > 0 ? '${((cal / totalCal) * 100).round()}%' : '0%';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.aiBlue, label: 'Prot. ${pct(goals.protein * 4)}'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.warning, label: 'Carbs ${pct(goals.carbs * 4)}'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.error, label: 'Gord. ${pct(goals.fat * 9)}'),
      ],
    );
  }
}

class MacroCard extends StatelessWidget {
  const MacroCard({
    super.key,
    required this.label,
    required this.amount,
    required this.calPerGram,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final int calPerGram;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            '${amount}g',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${amount * calPerGram} kcal',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MacroCardsRow extends StatelessWidget {
  const MacroCardsRow({super.key, required this.goals});

  final DailyGoals goals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MacroCard(
            label: 'Proteína',
            amount: goals.protein,
            calPerGram: 4,
            color: AppColors.aiBlue,
            icon: AppIcons.egg,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: MacroCard(
            label: 'Carboidratos',
            amount: goals.carbs,
            calPerGram: 4,
            color: AppColors.warning,
            icon: AppIcons.grains,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: MacroCard(
            label: 'Gordura',
            amount: goals.fat,
            calPerGram: 9,
            color: AppColors.error,
            icon: AppIcons.drop,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _MacroDonutPainter extends CustomPainter {
  const _MacroDonutPainter({
    required this.proteinCal,
    required this.carbsCal,
    required this.fatCal,
    required this.progress,
    required this.strokeWidth,
  });

  final double proteinCal;
  final double carbsCal;
  final double fatCal;
  final double progress;
  final double strokeWidth;

  static const double _gapAngle = 0.055;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2) - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    paint.color = AppColors.borderDefault;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    final total = proteinCal + carbsCal + fatCal;
    if (total == 0 || progress == 0) return;

    final fullCircle = 2 * math.pi * progress;
    final proteinSweep =
        math.max(0.0, (proteinCal / total) * fullCircle - _gapAngle);
    final carbsSweep =
        math.max(0.0, (carbsCal / total) * fullCircle - _gapAngle);
    final fatSweep = math.max(0.0, (fatCal / total) * fullCircle - _gapAngle);

    var startAngle = -math.pi / 2;

    paint.color = AppColors.aiBlue;
    canvas.drawArc(rect, startAngle, proteinSweep, false, paint);
    startAngle += proteinSweep + _gapAngle;

    paint.color = AppColors.warning;
    canvas.drawArc(rect, startAngle, carbsSweep, false, paint);
    startAngle += carbsSweep + _gapAngle;

    paint.color = AppColors.error;
    canvas.drawArc(rect, startAngle, fatSweep, false, paint);
  }

  @override
  bool shouldRepaint(_MacroDonutPainter old) =>
      old.progress != progress ||
      old.proteinCal != proteinCal ||
      old.carbsCal != carbsCal ||
      old.fatCal != fatCal;
}
