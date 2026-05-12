import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/calendar_today.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/models/day_meal_log.dart';
import 'package:rud_fits_ai/services/meal_log_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';

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

  void _shiftDay(int delta) {
    final next = _day.add(Duration(days: delta));
    if (next.isAfter(_todayOnly)) return;
    AppHaptics.selection();
    setState(() => _day = next);
    _fetch();
  }

  String _formatHeaderDate() {
    return '${_day.day} de ${_monthsPt[_day.month - 1]} de ${_day.year}';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _quantityLabel(DayMealLogItem item) {
    if (item.unitType == 1) {
      return '${item.quantity} g';
    }
    return '${item.quantity} u.';
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftDay(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.textPrimary,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Refeições do dia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatHeaderDate(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _day.isBefore(_todayOnly) ? () => _shiftDay(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
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
                            formatTime: _formatTime,
                            quantityLabel: _quantityLabel,
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
                      Icons.cloud_off_rounded,
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
                    icon: const Icon(Icons.refresh_rounded, size: 18),
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
    required this.formatTime,
    required this.quantityLabel,
    required this.onRefresh,
  });

  final List<DayMealLogEntry> logs;
  final int dayTotalKcal;
  final double dayProtein;
  final double dayCarbs;
  final double dayFat;
  final String Function(DateTime?) formatTime;
  final String Function(DayMealLogItem) quantityLabel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primaryGreen,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: _DaySummaryCard(
                  kcal: 0,
                  protein: 0,
                  carbs: 0,
                  fat: 0,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardElevated,
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 36,
                        color: AppColors.lightGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nada registrado neste dia',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Suas refeições aparecerão aqui com calorias e macros por alimento.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          _DaySummaryCard(
            kcal: dayTotalKcal,
            protein: dayProtein,
            carbs: dayCarbs,
            fat: dayFat,
          ),
          const SizedBox(height: 16),
          Text(
            '${logs.length} ${logs.length == 1 ? 'refeição' : 'refeições'}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...logs.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MealCard(
                entry: e,
                formatTime: formatTime,
                quantityLabel: quantityLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Total do dia',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$kcal kcal',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MacroPill(
                  label: 'P',
                  value: protein,
                  fractionDigits: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPill(
                  label: 'C',
                  value: carbs,
                  fractionDigits: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPill(
                  label: 'G',
                  value: fat,
                  fractionDigits: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.value,
    required this.fractionDigits,
  });

  final String label;
  final double value;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(fractionDigits)} g',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.entry,
    required this.formatTime,
    required this.quantityLabel,
  });

  final DayMealLogEntry entry;
  final String Function(DateTime?) formatTime;
  final String Function(DayMealLogItem) quantityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = formatTime(entry.consumedAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.set_meal_rounded,
              color: AppColors.lightGreen,
              size: 22,
            ),
          ),
          title: Text(
            entry.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  t,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.totalCalories} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Text(
              'Macros: P ${entry.totalProtein.toStringAsFixed(0)} g · '
              'C ${entry.totalCarbs.toStringAsFixed(1)} g · '
              'G ${entry.totalFat.toStringAsFixed(1)} g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Alimentos (${entry.items.length})',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...entry.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.foodName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${item.calories} kcal',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quantityLabel(item),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'P ${item.protein.toStringAsFixed(0)} g · '
                        'C ${item.carbs.toStringAsFixed(1)} g · '
                        'G ${item.fat.toStringAsFixed(1)} g',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}