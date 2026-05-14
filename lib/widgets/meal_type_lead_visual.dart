import 'package:flutter/material.dart';

import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class MealTypeLeadVisual extends StatelessWidget {
  const MealTypeLeadVisual({
    super.key,
    required this.mealType,
    this.size = 48,
    this.borderRadius,
    this.showBorder = true,
    this.backgroundColor,
    this.fit = BoxFit.cover,
  });

  final MealType mealType;
  final double size;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? backgroundColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(size * 0.255);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardElevated,
        borderRadius: br,
        border: showBorder
            ? Border.all(color: AppColors.borderDefault)
            : null,
      ),
      child: Image.asset(
        mealType.pickerLeadingAssetPath,
        fit: fit,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: size * 0.4,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
