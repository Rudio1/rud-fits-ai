import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/meal_type_lead_visual.dart';

class MealTypeOptionTile extends StatelessWidget {
  const MealTypeOptionTile({
    super.key,
    required this.type,
    required this.onTap,
  });

  final MealType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                MealTypeLeadVisual(
                  mealType: type,
                  size: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    type.labelPt,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.caretRight,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MealTypeChipSelector extends StatelessWidget {
  const MealTypeChipSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final MealType? selected;
  final ValueChanged<MealType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MealType.values.map((t) {
        final isSelected = selected == t;
        return ChoiceChip(
          showCheckmark: false,
          selected: isSelected,
          onSelected: enabled
              ? (_) {
                  AppHaptics.selection();
                  onChanged(t);
                }
              : null,
          avatar: MealTypeLeadVisual(
            mealType: t,
            size: 22,
            borderRadius: BorderRadius.circular(11),
            showBorder: false,
          ),
          label: Text(t.labelPt),
          selectedColor: AppColors.primaryGreen,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? AppColors.buttonText : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderDefault,
          ),
          backgroundColor: AppColors.card,
        );
      }).toList(),
    );
  }
}
