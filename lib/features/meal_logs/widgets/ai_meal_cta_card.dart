import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class AiMealCtaCard extends StatelessWidget {
  const AiMealCtaCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.mealsAiRegistrarDeep.withValues(alpha: 0.22),
                AppColors.mealsAiRegistrarAccent.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              color: AppColors.mealsAiRegistrarAccent.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.mealsAiRegistrarAccent.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        AppColors.mealsAiRegistrarAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.mealsAiRegistrarMuted
                          .withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    AppIcons.sparkle,
                    color: AppColors.mealsAiRegistrarMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Registrar refeição com IA',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mealsAiRegistrarDeep
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.mealsAiRegistrarAccent
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'Câmera',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.mealsAiRegistrarMuted,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tipo da refeição, uma foto do prato, e a IA sugere alimentos e calorias. Você revisa tudo com calma antes de salvar.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  AppIcons.camera,
                  size: 22,
                  color:
                      AppColors.mealsAiRegistrarMuted.withValues(alpha: 0.95),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
