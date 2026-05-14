import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/meal_logs/screens/meal_log_edit_screen.dart';
import 'package:rud_fits_ai/features/meal_logs/widgets/meal_log_detail_view.dart';
import 'package:rud_fits_ai/models/day_meal_log.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class MealLogDetailScreen extends StatefulWidget {
  const MealLogDetailScreen({super.key, required this.meal});

  final DayMealLogEntry meal;

  @override
  State<MealLogDetailScreen> createState() => _MealLogDetailScreenState();
}

class _MealLogDetailScreenState extends State<MealLogDetailScreen> {
  late DayMealLogEntry _meal;
  bool _needsListRefresh = false;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
  }

  void _popToList() {
    Navigator.of(context).pop(_needsListRefresh);
  }

  Future<void> _openEdit() async {
    AppHaptics.selection();
    final updated = await Navigator.of(context).push<DayMealLogEntry?>(
      AppTransitions.slideFromRight(
        page: MealLogEditScreen(meal: _meal),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _meal = updated;
        _needsListRefresh = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_needsListRefresh);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.caretLeft, size: 22),
            onPressed: _popToList,
          ),
          title: const Text('Detalhe da refeição'),
          actions: [
            IconButton(
              onPressed: _openEdit,
              icon: const Icon(AppIcons.pencilSimple, size: 22),
              tooltip: 'Editar',
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: MealLogDetailView(meal: _meal),
        ),
      ),
    );
  }
}
