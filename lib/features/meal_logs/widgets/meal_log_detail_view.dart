import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/meal_logs/meal_log_format.dart';
import 'package:rud_fits_ai/features/meal_logs/meal_macro_total_insight.dart';
import 'package:rud_fits_ai/features/meal_logs/widgets/meal_macro_chart_card.dart';
import 'package:rud_fits_ai/features/meal_logs/widgets/meal_macro_total_insight_card.dart';
import 'package:rud_fits_ai/models/day_meal_log.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/meal_type_lead_visual.dart';

class MealLogDetailView extends StatelessWidget {
  const MealLogDetailView({
    super.key,
    required this.meal,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
  });

  final DayMealLogEntry meal;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = MealLogFormat.consumedTime(meal.consumedAt);
    final praise = MealMacroPraise.fromGrams(
      proteinG: meal.totalProtein,
      carbsG: meal.totalCarbs,
      fatG: meal.totalFat,
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MealDetailHero(
            mealType: MealType.fromApiValue(meal.mealType),
            name: meal.name,
            timeLabel: timeLabel,
            totalCalories: meal.totalCalories,
            notes: meal.notes,
          ),
          const SizedBox(height: 28),
          Text(
            'Macronutrientes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          MealMacroChartCard(
            protein: meal.totalProtein,
            carbs: meal.totalCarbs,
            fat: meal.totalFat,
          ),
          const SizedBox(height: 14),
          if (praise != null) ...[
            MealMacroTotalInsightCard(praise: praise),
            const SizedBox(height: 28),
          ] else
            const SizedBox(height: 28),
          Row(
            children: [
              Text(
                'Alimentos',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Text(
                  '${meal.items.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meal.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Text(
                'Nenhum alimento listado para esta refeição.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderDefault),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < meal.items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderDefault.withValues(alpha: 0.65),
                      ),
                    MealLogFoodItemCard(
                      index: i + 1,
                      item: meal.items[i],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MealDetailHero extends StatelessWidget {
  const _MealDetailHero({
    required this.mealType,
    required this.name,
    required this.timeLabel,
    required this.totalCalories,
    required this.notes,
  });

  final MealType mealType;
  final String name;
  final String timeLabel;
  final int totalCalories;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.primaryGreen.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: MealTypeLeadVisual(
                  mealType: mealType,
                  size: 56,
                  borderRadius: BorderRadius.circular(12),
                  showBorder: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: AppIcons.clock,
                          label: timeLabel,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '$totalCalories kcal',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              notes!.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MealLogFoodItemCard extends StatelessWidget {
  const MealLogFoodItemCard({
    super.key,
    required this.index,
    required this.item,
    this.quantityOverride,
  });

  final int index;
  final DayMealLogItem item;
  final String? quantityOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = quantityOverride ?? MealLogFormat.itemQuantity(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '$index',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.lightGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.foodName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.calories} kcal',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                AppIcons.scales,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  qty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderDefault.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FoodMacroCell(
                    label: 'Proteína',
                    value: item.protein,
                    fractionDigits: 0,
                    accent: AppColors.aiBlue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: AppColors.borderDefault.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _FoodMacroCell(
                    label: 'Carbos',
                    value: item.carbs,
                    fractionDigits: 1,
                    accent: AppColors.lightGreen,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: AppColors.borderDefault.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _FoodMacroCell(
                    label: 'Gordura',
                    value: item.fat,
                    fractionDigits: 1,
                    accent: AppColors.warning,
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

class _FoodMacroCell extends StatelessWidget {
  const _FoodMacroCell({
    required this.label,
    required this.value,
    required this.fractionDigits,
    required this.accent,
  });

  final String label;
  final double value;
  final int fractionDigits;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(fractionDigits)} g',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: accent,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
