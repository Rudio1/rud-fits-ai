import 'package:flutter/material.dart';

import 'package:rud_fits_ai/features/meal_logs/meal_macro_total_insight.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class MealMacroTotalInsightCard extends StatelessWidget {
  const MealMacroTotalInsightCard({super.key, required this.praise});

  final MealMacroPraise praise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            praise.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            praise.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
