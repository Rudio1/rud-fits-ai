import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/scanner/screens/meal_saved_success_screen.dart';
import 'package:rud_fits_ai/models/analyzed_meal.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/services/meal_log_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/meal_type_picker.dart';

class ConfirmMealScreen extends StatefulWidget {
  const ConfirmMealScreen({
    super.key,
    required this.meal,
    this.initialMealType,
  });

  final AnalyzedMeal meal;
  final MealType? initialMealType;

  @override
  State<ConfirmMealScreen> createState() => _ConfirmMealScreenState();
}

class _ConfirmMealScreenState extends State<ConfirmMealScreen> {
  late final List<AnalyzedFood> _foods;
  bool _saving = false;
  MealType? _mealType;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
    _foods = widget.meal.foods.map((f) => f.copy()).toList();
  }

  int get _totalGrams =>
      _foods.fold<int>(0, (sum, f) => sum + f.estimatedQuantityGrams);

  double get _totalCalories =>
      _foods.fold<double>(0, (sum, f) => sum + (f.caloriesKcal ?? 0));

  double get _totalProtein =>
      _foods.fold<double>(0, (sum, f) => sum + (f.proteinGrams ?? 0));

  double get _totalCarbs =>
      _foods.fold<double>(0, (sum, f) => sum + (f.carbohydratesGrams ?? 0));

  double get _totalFat =>
      _foods.fold<double>(0, (sum, f) => sum + (f.fatGrams ?? 0));

  bool get _hasCompleteEstimatedNutrition =>
      _foods.isNotEmpty &&
      _foods.every(
        (food) =>
            food.caloriesKcal != null &&
            food.proteinGrams != null &&
            food.carbohydratesGrams != null &&
            food.fatGrams != null,
      );

  void _updateFood(int index, AnalyzedFood next) {
    setState(() => _foods[index] = next);
  }

  void _removeFood(int index) {
    AppHaptics.selection();
    setState(() => _foods.removeAt(index));
  }

  void _addFood() {
    AppHaptics.selection();
    setState(() {
      _foods.add(AnalyzedFood(name: '', estimatedQuantityGrams: 100));
    });
  }

  Future<void> _confirm() async {
    if (_saving) return;
    if (_mealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo da refeição.')),
      );
      return;
    }
    if (_foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item.')),
      );
      return;
    }

    for (final f in _foods) {
      if (f.name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha o nome de todos os itens.')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    final draft = AnalyzedMeal(foods: List<AnalyzedFood>.from(_foods));
    final estimated = await MealLogApiService.estimateDetectedFoodsNutrition(
      draft,
    );

    if (!mounted) return;

    if (!estimated.ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estimated.error ?? 'Não foi possível recalcular os itens.',
          ),
        ),
      );
      return;
    }

    for (final f in estimated.meal!.foods) {
      if (f.foodId == null || f.foodId!.trim().isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não encontramos um alimento cadastrado para um dos itens. Ajuste o nome ou a quantidade.',
            ),
          ),
        );
        return;
      }
    }

    final saveResult = await MealLogApiService.saveFromDetectedFoods(
      mealType: _mealType!.apiValue,
      consumedAtUtc: DateTime.now(),
      foodsWithIds: estimated.meal!.foods,
    );

    if (!mounted) return;

    if (!saveResult.ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveResult.error ?? 'Não foi possível salvar a refeição.',
          ),
        ),
      );
      return;
    }

    await AppHaptics.success();
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      AppTransitions.fade(
        page: MealSavedSuccessScreen(saved: saveResult.meal!),
      ),
    );
  }

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
        title: const Text('Confirmar refeição'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _OverviewCard(
                    itemCount: _foods.length,
                    totalGrams: _totalGrams,
                    totalCalories: _totalCalories,
                    totalProtein: _totalProtein,
                    totalCarbs: _totalCarbs,
                    totalFat: _totalFat,
                    hasCompleteEstimatedNutrition:
                        _hasCompleteEstimatedNutrition,
                  ),
                  const SizedBox(height: 14),
                  MealTypeChipSelector(
                    selected: _mealType,
                    enabled: !_saving,
                    onChanged: (t) => setState(() => _mealType = t),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Itens detectados',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _foods.isEmpty
                                  ? 'Adicione itens para registrar a refeição.'
                                  : 'Revise os nomes e ajuste a quantidade de cada alimento.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _InfoPill(
                        icon: AppIcons.forkKnife,
                        label:
                            '${_foods.length} ${_foods.length == 1 ? "item" : "itens"}',
                        backgroundColor: AppColors.card,
                        iconColor: AppColors.lightGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_foods.isEmpty)
                    _EmptyFoodsState(onAdd: _addFood)
                  else
                    ..._foods.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FoodTile(
                          key: ValueKey('food-$e.key'),
                          food: e.value,
                          onChange: (next) => _updateFood(e.key, next),
                          onRemove: () => _removeFood(e.key),
                          enabled: !_saving,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  _AddItemButton(onTap: _saving ? null : _addFood),
                ],
              ),
            ),
            _Footer(
              totalGrams: _totalGrams,
              itemCount: _foods.length,
              estimatedCalories: _totalCalories,
              showEstimatedCalories: _hasCompleteEstimatedNutrition,
              saving: _saving,
              canSubmit: _mealType != null && _foods.isNotEmpty,
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Food tile ────────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.itemCount,
    required this.totalGrams,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.hasCompleteEstimatedNutrition,
  });

  final int itemCount;
  final int totalGrams;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final bool hasCompleteEstimatedNutrition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 20,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  AppIcons.sparkle,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revise antes de salvar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A IA detectou $itemCount ${itemCount == 1 ? "item" : "itens"}. Ajuste o que for preciso e confirme a refeição.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: AppIcons.forkKnife,
                label: '$itemCount ${itemCount == 1 ? "item" : "itens"}',
                backgroundColor: AppColors.cardElevated,
                iconColor: AppColors.lightGreen,
              ),
              _InfoPill(
                icon: AppIcons.scales,
                label: '$totalGrams g',
                backgroundColor: AppColors.cardElevated,
                iconColor: AppColors.aiBlue,
              ),
              if (hasCompleteEstimatedNutrition)
                _InfoPill(
                  icon: AppIcons.flame,
                  label: '~ ${totalCalories.round()} kcal',
                  backgroundColor: AppColors.cardElevated,
                  iconColor: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasCompleteEstimatedNutrition)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroTag(
                  label: 'Proteína',
                  value: _formatGrams(totalProtein),
                  icon: AppIcons.barbell,
                  color: AppColors.aiBlue,
                ),
                _MacroTag(
                  label: 'Carbo',
                  value: _formatGrams(totalCarbs),
                  icon: AppIcons.grains,
                  color: AppColors.lightGreen,
                ),
                _MacroTag(
                  label: 'Gordura',
                  value: _formatGrams(totalFat),
                  icon: AppIcons.drop,
                  color: AppColors.warning,
                ),
              ],
            )
          else
            Text(
              'Os valores finais de calorias e macros serão recalculados quando você confirmar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.backgroundColor = AppColors.cardElevated,
    this.iconColor = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroTag extends StatelessWidget {
  const _MacroTag({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTile extends StatefulWidget {
  const _FoodTile({
    super.key,
    required this.food,
    required this.onChange,
    required this.onRemove,
    required this.enabled,
  });

  final AnalyzedFood food;
  final ValueChanged<AnalyzedFood> onChange;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  State<_FoodTile> createState() => _FoodTileState();
}

class _FoodTileState extends State<_FoodTile> {
  late final TextEditingController _nameController;
  late final TextEditingController _gramsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.food.name);
    _gramsController = TextEditingController(
      text: widget.food.estimatedQuantityGrams.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  void _adjustGrams(int delta) {
    final current = int.tryParse(_gramsController.text) ?? 0;
    final next = (current + delta).clamp(0, 9999);
    AppHaptics.selection();
    _gramsController.text = next.toString();
    widget.onChange(
      widget.food.copyWithEdit(
        name: _nameController.text.trim(),
        estimatedQuantityGrams: next,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEstimatedNutrition =
        widget.food.caloriesKcal != null &&
        widget.food.proteinGrams != null &&
        widget.food.carbohydratesGrams != null &&
        widget.food.fatGrams != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  enabled: widget.enabled,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Nome do alimento',
                  ),
                  onChanged: (v) {
                    widget.onChange(
                      widget.food.copyWithEdit(
                        name: v,
                        estimatedQuantityGrams:
                            int.tryParse(_gramsController.text) ??
                            widget.food.estimatedQuantityGrams,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: widget.enabled ? widget.onRemove : null,
                  icon: const Icon(
                    AppIcons.trash,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Remover',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: AppIcons.scales,
                label: '${widget.food.estimatedQuantityGrams} g',
                backgroundColor: AppColors.cardElevated,
                iconColor: AppColors.aiBlue,
              ),
              if (widget.food.caloriesKcal != null)
                _InfoPill(
                  icon: AppIcons.flame,
                  label: '~ ${widget.food.caloriesKcal!.round()} kcal',
                  backgroundColor: AppColors.cardElevated,
                  iconColor: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantidade',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ajuste o peso estimado em gramas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StepperButton(
                      icon: AppIcons.minus,
                      onTap: widget.enabled ? () => _adjustGrams(-10) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _gramsController,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          filled: true,
                          fillColor: AppColors.card,
                          suffixText: 'g',
                          suffixStyle: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderDefault,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderDefault,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          widget.onChange(
                            widget.food.copyWithEdit(
                              name: _nameController.text.trim(),
                              estimatedQuantityGrams:
                                  int.tryParse(v) ??
                                  widget.food.estimatedQuantityGrams,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StepperButton(
                      icon: AppIcons.plus,
                      onTap: widget.enabled ? () => _adjustGrams(10) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (hasEstimatedNutrition)
            Row(
              children: [
                Expanded(
                  child: _MacroTag(
                    label: 'Proteína',
                    value: _formatGrams(widget.food.proteinGrams!),
                    icon: AppIcons.barbell,
                    color: AppColors.aiBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroTag(
                    label: 'Carbo',
                    value: _formatGrams(widget.food.carbohydratesGrams!),
                    icon: AppIcons.grains,
                    color: AppColors.lightGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroTag(
                    label: 'Gordura',
                    value: _formatGrams(widget.food.fatGrams!),
                    icon: AppIcons.drop,
                    color: AppColors.warning,
                  ),
                ),
              ],
            )
          else
            Text(
              'Os macros serão recalculados quando você confirmar a refeição.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.cardElevated
                : AppColors.cardElevated.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

// ─── Add item ─────────────────────────────────────────────────────────────────

class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderDefault,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                AppIcons.plusCircle,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Adicionar item manualmente',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state (lista zerada) ──────────────────────────────────────────────

class _EmptyFoodsState extends StatelessWidget {
  const _EmptyFoodsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardElevated,
            ),
            child: const Icon(AppIcons.forkKnife, color: AppColors.lightGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Sua refeição está vazia',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adicione pelo menos um item para registrar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(AppIcons.plus, size: 18),
            label: const Text('Adicionar item'),
          ),
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.totalGrams,
    required this.itemCount,
    required this.estimatedCalories,
    required this.showEstimatedCalories,
    required this.saving,
    required this.canSubmit,
    required this.onConfirm,
  });

  final int totalGrams;
  final int itemCount;
  final double estimatedCalories;
  final bool showEstimatedCalories;
  final bool saving;
  final bool canSubmit;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: AppIcons.forkKnife,
                  label: '$itemCount ${itemCount == 1 ? "item" : "itens"}',
                  backgroundColor: AppColors.card,
                  iconColor: AppColors.lightGreen,
                ),
                _InfoPill(
                  icon: AppIcons.scales,
                  label: '$totalGrams g',
                  backgroundColor: AppColors.card,
                  iconColor: AppColors.aiBlue,
                ),
                if (showEstimatedCalories)
                  _InfoPill(
                    icon: AppIcons.flame,
                    label: '~ ${estimatedCalories.round()} kcal',
                    backgroundColor: AppColors.card,
                    iconColor: AppColors.warning,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: MotionTokens.fast,
                child: ElevatedButton(
                  key: ValueKey(saving),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                  ),
                  onPressed: saving || !canSubmit ? null : onConfirm,
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.buttonText,
                          ),
                        )
                      : const Text('Confirmar refeição'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatGrams(double value) {
  if (value == value.roundToDouble()) {
    return '${value.toStringAsFixed(0)}g';
  }
  return '${value.toStringAsFixed(1)}g';
}
