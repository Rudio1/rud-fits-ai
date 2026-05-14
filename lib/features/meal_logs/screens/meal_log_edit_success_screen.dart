import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/shell/main_shell_screen.dart';
import 'package:rud_fits_ai/models/day_meal_log.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class MealLogEditSuccessScreen extends StatefulWidget {
  const MealLogEditSuccessScreen({super.key, required this.meal});

  final DayMealLogEntry meal;

  @override
  State<MealLogEditSuccessScreen> createState() =>
      _MealLogEditSuccessScreenState();
}

class _MealLogEditSuccessScreenState extends State<MealLogEditSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.medium,
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppHaptics.success();
      await Future<void>.delayed(const Duration(milliseconds: 1700));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppTransitions.fade(
          page: const MainShellScreen(initialIndex: 1),
        ),
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.meal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      AppIcons.check,
                      size: 52,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Edição realizada com sucesso!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  m.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${m.totalCalories} kcal · P ${m.totalProtein.toStringAsFixed(0)}g · C ${m.totalCarbs.toStringAsFixed(1)}g · G ${m.totalFat.toStringAsFixed(1)}g',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
