import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/auth_session.dart';
import 'package:rud_fits_ai/core/calendar_today.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/features/auth/screens/login_screen.dart';
import 'package:rud_fits_ai/features/scanner/screens/scanner_screen.dart';
import 'package:rud_fits_ai/models/daily_goals.dart';
import 'package:rud_fits_ai/services/daily_goals_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/charts/macro_donut.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DailyGoals? _goals;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!_loading) setState(() => _loading = true);
    final result = await DailyGoalsApiService.fetch();
    if (!mounted) return;
    setState(() {
      _goals = result.goals;
      _error = result.error;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final result = await DailyGoalsApiService.fetch();
    if (!mounted) return;
    setState(() {
      _goals = result.goals;
      _error = result.error;
    });
  }

  void _logout() {
    AppHaptics.selection();
    AuthSession.clear();
    Navigator.of(context).pushAndRemoveUntil(
      AppTransitions.fade(page: const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openScanner() async {
    AppHaptics.selection();
    await Navigator.of(context).push(
      AppTransitions.slideFromRight(page: const ScannerScreen()),
    );
    if (mounted) await _refresh();
  }

  String get _greeting {
    final hour = DateTime.now().toLocal().hour;

    final period = hour < 12
        ? 'Bom dia'
        : hour < 18
        ? 'Boa tarde'
        : 'Boa noite';

    final name = _displayName;

    return name == null ? period : '$period, $name';
  }

  String? get _displayName {
    final raw = AuthSession.username?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String get _today {
    const months = [
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
    final d = CalendarToday.dateOnlyLocal();
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryGreen,
          backgroundColor: AppColors.card,
          child: AnimatedSwitcher(
            duration: MotionTokens.medium,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _LoadingView(key: ValueKey('loading'));
    }
    if (_error != null && _goals == null) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: _error!,
        onRetry: _fetch,
      );
    }
    return _ContentView(
      key: const ValueKey('content'),
      goals: _goals!,
      greeting: _greeting,
      today: _today,
      onLogout: _logout,
      onAddMeal: _openScanner,
    );
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView({
    super.key,
    required this.goals,
    required this.greeting,
    required this.today,
    required this.onLogout,
    required this.onAddMeal,
  });

  final DailyGoals goals;
  final String greeting;
  final String today;
  final VoidCallback onLogout;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    today,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Sair',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _AddMealCard(onTap: onAddMeal),
        const SizedBox(height: 16),
        _GoalsCard(goals: goals),
        const SizedBox(height: 16),
        _GoalsExplanationCard(goals: goals),
      ],
    );
  }
}

class _AddMealCard extends StatelessWidget {
  const _AddMealCard({required this.onTap});

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
                AppColors.primaryGreen.withValues(alpha: 0.18),
                AppColors.premiumGreen.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: AppColors.primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Adicionar refeição',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.aiBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'IA',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.aiBlue,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tire uma foto e a IA detecta os alimentos para você.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});

  final DailyGoals goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Suas metas de hoje',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(child: MacroDonut(goals: goals)),
          const SizedBox(height: 12),
          MacroLegend(goals: goals),
          const SizedBox(height: 24),
          MacroCardsRow(goals: goals),
        ],
      ),
    );
  }
}

class _GoalsExplanationCard extends StatelessWidget {
  const _GoalsExplanationCard({required this.goals});

  final DailyGoals goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.lightGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Como funciona',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Para alcançar seu objetivo, mantenha um consumo próximo de ${goals.calories} kcal por dia, divididas entre proteína, carboidratos e gordura.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando seu dia...',
                  style: theme.textTheme.bodyMedium?.copyWith(
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
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
                      Icons.wifi_off_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Não conseguimos carregar seu dia',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
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
