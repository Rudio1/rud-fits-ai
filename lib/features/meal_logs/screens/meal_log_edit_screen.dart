import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/meal_logs/screens/meal_log_edit_success_screen.dart';
import 'package:rud_fits_ai/models/day_meal_log.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/services/meal_log_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/meal_type_picker.dart';

class _ItemEditors {
  _ItemEditors({
    required this.id,
    required this.nameController,
    required this.gramsController,
  });

  final String id;
  final TextEditingController nameController;
  final TextEditingController gramsController;
}

class MealLogEditScreen extends StatefulWidget {
  const MealLogEditScreen({super.key, required this.meal});

  final DayMealLogEntry meal;

  @override
  State<MealLogEditScreen> createState() => _MealLogEditScreenState();
}

class _MealLogEditScreenState extends State<MealLogEditScreen> {
  MealType? _mealType;
  late List<_ItemEditors> _items;
  bool _saving = false;

  int get _totalGrams => _items.fold<int>(
    0,
    (sum, row) => sum + (int.tryParse(row.gramsController.text) ?? 0),
  );

  @override
  void initState() {
    super.initState();
    final m = widget.meal;
    _mealType = MealType.fromApiValue(m.mealType);
    _items = m.items
        .map(
          (it) => _ItemEditors(
            id: it.id,
            nameController: TextEditingController(text: it.foodName),
            gramsController: TextEditingController(
              text: it.quantity.toString(),
            ),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final row in _items) {
      row.nameController.dispose();
      row.gramsController.dispose();
    }
    super.dispose();
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    AppHaptics.selection();
    final row = _items.removeAt(index);
    row.nameController.dispose();
    row.gramsController.dispose();
    setState(() {});
  }

  void _adjustGrams(_ItemEditors row, int delta) {
    final current = int.tryParse(row.gramsController.text) ?? 0;
    final next = (current + delta).clamp(0, 9999);
    AppHaptics.selection();
    row.gramsController.text = next.toString();
    setState(() {});
  }

  void _notifyItemChanged() {
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    final mt = _mealType;
    if (mt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo da refeição.')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mantenha pelo menos um item.')),
      );
      return;
    }

    final payloadItems = <Map<String, dynamic>>[];
    for (final row in _items) {
      final itemName = row.nameController.text.trim();
      if (itemName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha o nome de todos os itens.')),
        );
        return;
      }
      final g = int.tryParse(row.gramsController.text);
      if (g == null || g <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Informe uma quantidade válida em gramas para cada item.',
            ),
          ),
        );
        return;
      }
      if (row.id.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item sem identificador. Recarregue a lista.'),
          ),
        );
        return;
      }
      payloadItems.add({
        'id': row.id,
        'name': itemName,
        'estimatedQuantityGrams': g,
      });
    }

    setState(() => _saving = true);

    final result = await MealLogApiService.updateMealLog(
      mealLogId: widget.meal.id,
      mealType: mt.apiValue,
      items: payloadItems,
      previous: widget.meal,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Não foi possível salvar.')),
      );
      return;
    }

    await AppHaptics.success();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      AppTransitions.fade(page: MealLogEditSuccessScreen(meal: result.meal!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealType = _mealType ?? MealType.fromApiValue(widget.meal.mealType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.caretLeft, size: 22),
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Editar refeição'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _EditOverviewCard(
                    mealName: widget.meal.name,
                    mealTypeLabel: mealType.labelPt,
                    itemCount: _items.length,
                    totalGrams: _totalGrams,
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
                              'Itens da refeição',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Revise os nomes e ajuste o peso em gramas antes de salvar.',
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
                            '${_items.length} ${_items.length == 1 ? "item" : "itens"}',
                        backgroundColor: AppColors.card,
                        iconColor: AppColors.lightGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._items.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EditItemCard(
                        editors: e.value,
                        canRemove: _items.length > 1,
                        enabled: !_saving,
                        onRemove: () => _removeItem(e.key),
                        onAdjustGrams: (d) => _adjustGrams(e.value, d),
                        onChanged: _notifyItemChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _EditFooter(
              itemCount: _items.length,
              totalGrams: _totalGrams,
              saving: _saving,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditOverviewCard extends StatelessWidget {
  const _EditOverviewCard({
    required this.mealName,
    required this.mealTypeLabel,
    required this.itemCount,
    required this.totalGrams,
  });

  final String mealName;
  final String mealTypeLabel;
  final int itemCount;
  final int totalGrams;

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
          Text(
            mealName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: AppIcons.checkCircle,
                label: mealTypeLabel,
                backgroundColor: AppColors.cardElevated,
                iconColor: AppColors.primaryGreen,
              ),
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
            ],
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

class _EditItemCard extends StatelessWidget {
  const _EditItemCard({
    required this.editors,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
    required this.onAdjustGrams,
    required this.onChanged,
  });

  final _ItemEditors editors;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;
  final void Function(int delta) onAdjustGrams;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  controller: editors.nameController,
                  enabled: enabled,
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
                  onChanged: (_) => onChanged(),
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
                  onPressed: enabled && canRemove ? onRemove : null,
                  icon: const Icon(
                    AppIcons.trash,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Remover item',
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
                label: '${int.tryParse(editors.gramsController.text) ?? 0} g',
                backgroundColor: AppColors.cardElevated,
                iconColor: AppColors.aiBlue,
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
                  'Ajuste o peso em gramas para salvar a edição.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _GramStepperButton(
                      icon: AppIcons.minus,
                      enabled: enabled,
                      onTap: () => onAdjustGrams(-10),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: editors.gramsController,
                        enabled: enabled,
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
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GramStepperButton(
                      icon: AppIcons.plus,
                      enabled: enabled,
                      onTap: () => onAdjustGrams(10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditFooter extends StatelessWidget {
  const _EditFooter({
    required this.itemCount,
    required this.totalGrams,
    required this.saving,
    required this.onSave,
  });

  final int itemCount;
  final int totalGrams;
  final bool saving;
  final VoidCallback onSave;

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
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.buttonText,
                          ),
                        )
                      : const Text('Salvar alterações'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GramStepperButton extends StatelessWidget {
  const _GramStepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
