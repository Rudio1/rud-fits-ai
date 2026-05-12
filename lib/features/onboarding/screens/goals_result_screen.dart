import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/features/shell/main_shell_screen.dart';
import 'package:rud_fits_ai/models/daily_goals.dart';
import 'package:rud_fits_ai/services/daily_goals_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';
import 'package:rud_fits_ai/widgets/charts/macro_donut.dart';

class GoalsResultScreen extends StatefulWidget {
  const GoalsResultScreen({super.key});

  @override
  State<GoalsResultScreen> createState() => _GoalsResultScreenState();
}

class _GoalsResultScreenState extends State<GoalsResultScreen> {
  DailyGoals? _goals;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    if (!_loading) setState(() => _loading = true);

    final result = await DailyGoalsApiService.calculate();
    if (!mounted) return;

    setState(() {
      _goals = result.goals;
      _error = result.error;
      _loading = false;
    });
  }

  void _goToHome() {
    AppHaptics.success();
    Navigator.of(context).pushReplacement(
      AppTransitions.fade(page: const MainShellScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: MotionTokens.medium,
          child: _loading
              ? const _LoadingView(key: ValueKey('loading'))
              : _error != null
                  ? _ErrorView(
                      key: const ValueKey('error'),
                      message: _error!,
                      onRetry: _calculate,
                      onSkip: _goToHome,
                    )
                  : _ResultsView(
                      key: const ValueKey('results'),
                      goals: _goals!,
                      onStart: _goToHome,
                    ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: AppColors.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Calculando seu plano...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Isso leva apenas um instante.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onSkip,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Algo deu errado',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onSkip,
              child: const Text('Pular e continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    super.key,
    required this.goals,
    required this.onStart,
  });

  final DailyGoals goals;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seu plano\nestá pronto!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculamos tudo com base no seu perfil.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Center(child: MacroDonut(goals: goals)),
          const SizedBox(height: 16),
          MacroLegend(goals: goals),
          const SizedBox(height: 28),
          MacroCardsRow(goals: goals),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Valores calculados com base no seu peso, altura, objetivo e nível de atividade. Você pode ajustá-los nas configurações a qualquer momento.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: onStart,
            child: const Text('Começar minha jornada'),
          ),
        ],
      ),
    );
  }
}
