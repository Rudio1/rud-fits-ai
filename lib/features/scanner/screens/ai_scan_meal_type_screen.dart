import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/scanner/screens/scanner_screen.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/meal_type_picker.dart';

class AiScanMealTypeScreen extends StatelessWidget {
  const AiScanMealTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.caretLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Registrar com IA'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Qual refeição é essa?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha o tipo e abra a câmera. A IA reconhece o prato, sugere alimentos e calorias — você confere e ajusta antes de salvar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ...MealType.values.map(
              (type) => MealTypeOptionTile(
                type: type,
                onTap: () {
                  AppHaptics.selection();
                  Navigator.of(context).push(
                    AppTransitions.slideFromRight(
                      page: ScannerScreen(mealType: type),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
