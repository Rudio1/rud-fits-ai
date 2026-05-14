import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/calendar_today.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/meal_logs/meal_log_format.dart';
import 'package:rud_fits_ai/features/meal_logs/screens/meal_log_detail_screen.dart';
import 'package:rud_fits_ai/features/meal_logs/widgets/ai_meal_cta_card.dart';
import 'package:rud_fits_ai/features/scanner/screens/ai_scan_meal_type_screen.dart';
import 'package:rud_fits_ai/models/day_meal_log.dart';
import 'package:rud_fits_ai/models/meal_type.dart';
import 'package:rud_fits_ai/services/meal_log_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/meal_type_lead_visual.dart';

class DailyMealsScreen extends StatefulWidget {
  const DailyMealsScreen({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<DailyMealsScreen> createState() => _DailyMealsScreenState();
}

class _DailyMealsScreenState extends State<DailyMealsScreen> {
  late DateTime _day;
  List<DayMealLogEntry>? _logs;
  String? _error;
  bool _loading = true;

  static const _monthsPt = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  DateTime get _todayOnly => CalendarToday.dateOnlyLocal();

  @override
  void initState() {
    super.initState();
    _day = _todayOnly;
    _fetch();
  }

  @override
  void didUpdateWidget(covariant DailyMealsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await MealLogApiService.fetchLogsForDate(_day);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _logs = result.logs;
        _error = null;
      } else {
        _logs = null;
        _error = result.error;
      }
    });
  }

  Future<void> _onRefresh() async {
    final result = await MealLogApiService.fetchLogsForDate(_day);
    if (!mounted) return;
    setState(() {
      if (result.ok) {
        _logs = result.logs;
        _error = null;
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _openScanner() async {
    AppHaptics.selection();
    await Navigator.of(context).push(
      AppTransitions.slideFromRight(page: const AiScanMealTypeScreen()),
    );
    if (mounted) await _fetch();
  }

  Future<void> _pickDay() async {
    AppHaptics.selection();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day.isAfter(_todayOnly) ? _todayOnly : _day,
      firstDate: DateTime(2020),
      lastDate: _todayOnly,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.mealsSummaryDeep,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    final next = CalendarToday.dateOnlyLocal(picked);
    if (next.isAfter(_todayOnly)) return;
    setState(() => _day = next);
    _fetch();
  }

  String _formatHeaderDate() {
    return '${_day.day} de ${_monthsPt[_day.month - 1]} de ${_day.year}';
  }

  List<DayMealLogEntry> _sortedLogs() {
    final list = List<DayMealLogEntry>.from(_logs ?? const []);
    list.sort((a, b) {
      final ta = a.consumedAt;
      final tb = b.consumedAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    return list;
  }

  int _dayTotalKcal() {
    return _logs?.fold<int>(0, (s, e) => s + e.totalCalories) ?? 0;
  }

  double _dayTotalProtein() {
    return _logs?.fold<double>(0, (s, e) => s + e.totalProtein) ?? 0;
  }

  double _dayTotalCarbs() {
    return _logs?.fold<double>(0, (s, e) => s + e.totalCarbs) ?? 0;
  }

  double _dayTotalFat() {
    return _logs?.fold<double>(0, (s, e) => s + e.totalFat) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Text(
                    'Refeições',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: 'Escolher data',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickDay,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatHeaderDate(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _pickDay,
                        tooltip: 'Escolher data',
                        icon: Icon(
                          AppIcons.calendar,
                          size: 24,
                          color: AppColors.mealsSummaryAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: AiMealCtaCard(onTap: _openScanner),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: MotionTokens.normal,
                child: _loading
                    ? const _LoadingBody(key: ValueKey('loading'))
                    : _error != null && _logs == null
                        ? _ErrorBody(
                            key: const ValueKey('error'),
                            message: _error!,
                            onRetry: _fetch,
                          )
                        : _MealsBody(
                            key: ValueKey('ok-$_day'),
                            logs: _sortedLogs(),
                            dayTotalKcal: _dayTotalKcal(),
                            dayProtein: _dayTotalProtein(),
                            dayCarbs: _dayTotalCarbs(),
                            dayFat: _dayTotalFat(),
                            onRefresh: _onRefresh,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryGreen.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando refeições…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      AppIcons.cloudSlash,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Não foi possível carregar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(AppIcons.arrowClockwise, size: 18),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealsBody extends StatelessWidget {
  const _MealsBody({
    super.key,
    required this.logs,
    required this.dayTotalKcal,
    required this.dayProtein,
    required this.dayCarbs,
    required this.dayFat,
    required this.onRefresh,
  });

  final List<DayMealLogEntry> logs;
  final int dayTotalKcal;
  final double dayProtein;
  final double dayCarbs;
  final double dayFat;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primaryGreen,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _DayHeroSummary(
                  kcal: 0,
                  protein: 0,
                  carbs: 0,
                  fat: 0,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: _SectionHeader(count: 0),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, 0, 32, 24 + bottomInset),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryGreen.withValues(alpha: 0.18),
                            AppColors.cardElevated,
                          ],
                        ),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: const Icon(
                        AppIcons.forkKnife,
                        size: 38,
                        color: AppColors.lightGreen,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Nenhuma refeição neste dia',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque em “Registrar refeição com IA” acima e use a câmera para incluir a primeira refeição do dia.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryGreen,
      backgroundColor: AppColors.card,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 108 + bottomInset),
        children: [
          _DayHeroSummary(
            kcal: dayTotalKcal,
            protein: dayProtein,
            carbs: dayCarbs,
            fat: dayFat,
          ),
          const SizedBox(height: 22),
          _SectionHeader(count: logs.length),
          const SizedBox(height: 14),
          ...logs.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _MealListCard(entry: e, onRefresh: onRefresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count == 0
        ? 'Nenhuma refeição'
        : count == 1
            ? '1 refeição neste dia'
            : '$count refeições neste dia';

    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Suas refeições',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MealListCard extends StatelessWidget {
  const _MealListCard({required this.entry, required this.onRefresh});

  final DayMealLogEntry entry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = MealLogFormat.consumedTime(entry.consumedAt);
    final mealCategory = MealType.fromApiValue(entry.mealType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          AppHaptics.selection();
          final refresh = await Navigator.of(context).push<bool>(
            AppTransitions.slideFromRight(
              page: MealLogDetailScreen(meal: entry),
            ),
          );
          if (!context.mounted) return;
          if (refresh == true) await onRefresh();
        },

        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppColors.card,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MealTypeLeadVisual(
                  mealType: mealCategory,
                  size: 48,
                  borderRadius: BorderRadius.circular(14),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppIcons.clock,
                                size: 15,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.95),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primaryGreen
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '${entry.totalCalories} kcal',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      Icon(
                        AppIcons.caretRight,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        size: 28,
                      ),
                      Text(
                        'Detalhes',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeroSummary extends StatelessWidget {
  const _DayHeroSummary({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.mealsSummaryDeep.withValues(alpha: 0.14),
            AppColors.cardElevated.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        border: Border.all(
          color: AppColors.mealsSummaryAccent.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mealsSummaryAccent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      AppColors.mealsSummaryAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.mealsSummaryAccent.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.mealsSummaryAccent.withValues(alpha: 0.14),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.chartLine,
                  color: AppColors.mealsSummaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do dia',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.mealsSummaryAccent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Calorias e macros que você já registrou hoje',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$kcal',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderDefault.withValues(alpha: 0.9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MacroSummaryCell(
                    title: 'Proteína',
                    value: protein,
                    fractionDigits: 0,
                    accent: AppColors.aiBlue,
                  ),
                ),
                _MacroDivider(),
                Expanded(
                  child: _MacroSummaryCell(
                    title: 'Carboidr.',
                    value: carbs,
                    fractionDigits: 1,
                    accent: AppColors.accentSage,
                  ),
                ),
                _MacroDivider(),
                Expanded(
                  child: _MacroSummaryCell(
                    title: 'Gordura',
                    value: fat,
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

class _MacroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.borderDefault,
    );
  }
}

class _MacroSummaryCell extends StatelessWidget {
  const _MacroSummaryCell({
    required this.title,
    required this.value,
    required this.fractionDigits,
    required this.accent,
  });

  final String title;
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
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${value.toStringAsFixed(fractionDigits)} g',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ],
    );
  }
}

