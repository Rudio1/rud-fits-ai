import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/features/scanner/screens/meal_saved_success_screen.dart';
import 'package:rud_fits_ai/models/analyzed_meal.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/services/meal_log_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class ConfirmMealScreen extends StatefulWidget {
  const ConfirmMealScreen({super.key, required this.meal});

  final AnalyzedMeal meal;

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
    _foods = widget.meal.foods.map((f) => f.copy()).toList();
  }

  int get _totalGrams =>
      _foods.fold<int>(0, (sum, f) => sum + f.estimatedQuantityGrams);

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
    final estimated =
        await MealLogApiService.estimateDetectedFoodsNutrition(draft);

    if (!mounted) return;

    if (!estimated.ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estimated.error ?? 'Não foi possível recalcular os itens.'),
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
          content: Text(saveResult.error ?? 'Não foi possível salvar a refeição.'),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A IA detectou ${_foods.length} ${_foods.length == 1 ? "item" : "itens"}. Edite ou remova se precisar.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tipo da refeição',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MealType.values.map((t) {
                      final selected = _mealType == t;
                      return ChoiceChip(
                        showCheckmark: false,
                        selected: selected,
                        onSelected: _saving
                            ? null
                            : (_) {
                                AppHaptics.selection();
                                setState(() => _mealType = t);
                              },
                        avatar: Icon(
                          t.icon,
                          size: 16,
                          color: selected
                              ? AppColors.buttonText
                              : AppColors.primaryGreen,
                        ),
                        label: Text(t.labelPt),
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? AppColors.buttonText
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primaryGreen
                              : AppColors.borderDefault,
                        ),
                        backgroundColor: AppColors.card,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
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
    widget.onChange(widget.food.copyWithEdit(
      name: _nameController.text.trim(),
      estimatedQuantityGrams: next,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 18,
                  color: AppColors.lightGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  enabled: widget.enabled,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
                    widget.onChange(widget.food.copyWithEdit(
                      name: v,
                      estimatedQuantityGrams:
                          int.tryParse(_gramsController.text) ??
                              widget.food.estimatedQuantityGrams,
                    ));
                  },
                ),
              ),
              IconButton(
                onPressed: widget.enabled ? widget.onRemove : null,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Remover',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
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
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    filled: true,
                    fillColor: AppColors.cardElevated,
                    suffixText: 'g',
                    suffixStyle: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    widget.onChange(widget.food.copyWithEdit(
                      name: _nameController.text.trim(),
                      estimatedQuantityGrams:
                          int.tryParse(v) ?? widget.food.estimatedQuantityGrams,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 8),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: widget.enabled ? () => _adjustGrams(10) : null,
              ),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 6),
          if (widget.food.caloriesKcal != null)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '~ ${widget.food.caloriesKcal!.round()} kcal · '
                  'P ${(widget.food.proteinGrams ?? 0).toStringAsFixed(0)}g · '
                  'C ${(widget.food.carbohydratesGrams ?? 0).toStringAsFixed(1)}g · '
                  'G ${(widget.food.fatGrams ?? 0).toStringAsFixed(1)}g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
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
                Icons.add_circle_outline_rounded,
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
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.lightGreen,
            ),
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
            icon: const Icon(Icons.add_rounded, size: 18),
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
    required this.saving,
    required this.canSubmit,
    required this.onConfirm,
  });

  final int totalGrams;
  final int itemCount;
  final bool saving;
  final bool canSubmit;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$itemCount ${itemCount == 1 ? "item" : "itens"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$totalGrams g no total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
