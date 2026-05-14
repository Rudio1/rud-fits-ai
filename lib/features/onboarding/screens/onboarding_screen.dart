import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/onboarding/screens/goals_result_screen.dart';
import 'package:rud_fits_ai/models/user_profile.dart';
import 'package:rud_fits_ai/services/onboarding_api_service.dart';
import 'package:rud_fits_ai/services/profile_api_service.dart';
import 'package:rud_fits_ai/shared/formatters/auto_decimal_formatter.dart';
import 'package:rud_fits_ai/themes/themes.dart';

enum _OnboardingStep {
  goal,
  gender,
  bodyMetrics,
  weightJourney,
  dailyRoutineLevel,
  activityLevel,
  goalIntensity,
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.seedProfile, this.onRecalculateDone});

  final UserProfile? seedProfile;
  final VoidCallback? onRecalculateDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  _OnboardingStep _step = _OnboardingStep.goal;
  String? _errorMessage;
  bool _busy = false;

  int? _goal;
  int? _gender;
  int? _activityLevel;
  int? _dailyRoutineLevel;
  int? _goalIntensity;

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  final _ageFocus = FocusNode();
  final _heightFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _targetWeightFocus = FocusNode();

  late final AnimationController _shakeController;

  int get _stepIndex => _step.index;
  int get _stepCount => _OnboardingStep.values.length;
  bool get _isLastStep => _step == _OnboardingStep.goalIntensity;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: MotionTokens.normal);
    final seed = widget.seedProfile;
    if (seed != null) {
      _applySeed(seed);
    }
  }

  void _applySeed(UserProfile p) {
    _goal = p.goal;
    _gender = p.gender;
    _activityLevel = p.activityLevel;
    _dailyRoutineLevel = p.dailyRoutineLevel;
    _goalIntensity = p.goalIntensity;
    _ageController.text = '${p.age}';
    final hM = p.height / 100.0;
    _heightController.text =
        hM.toStringAsFixed(2).replaceFirst('.', ',');
    _weightController.text = '${p.weight}';
    _targetWeightController.text = '${p.targetWeight}';
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _ageFocus.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    _targetWeightFocus.dispose();
    super.dispose();
  }

  Future<void> _shake() async {
    await _shakeController.forward(from: 0);
    _shakeController.reset();
  }

  String? _validateCurrent() {
    return switch (_step) {
      _OnboardingStep.goal =>
        _goal == null ? 'Selecione um objetivo para continuar' : null,
      _OnboardingStep.gender =>
        _gender == null ? 'Selecione uma opção para continuar' : null,
      _OnboardingStep.bodyMetrics => _validateBodyMetrics(),
      _OnboardingStep.weightJourney => _validateWeightJourney(),
      _OnboardingStep.dailyRoutineLevel =>
        _dailyRoutineLevel == null ? 'Selecione sua rotina diária' : null,
      _OnboardingStep.activityLevel =>
        _activityLevel == null ? 'Selecione seu nível de atividade' : null,
      _OnboardingStep.goalIntensity =>
        _goalIntensity == null ? 'Selecione o ritmo desejado' : null,
    };
  }

  String? _validateBodyMetrics() {
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 10 || age > 120) {
      return 'Informe uma idade válida entre 10 e 120 anos';
    }
    final height =
        double.tryParse(_heightController.text.trim().replaceAll(',', '.'));
    if (height == null || height < 0.5 || height > 3.0) {
      return 'Informe uma altura válida em metros (ex.: 1,80)';
    }
    final weight =
        double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    if (weight == null || weight < 20 || weight > 500) {
      return 'Informe um peso válido em kg (ex.: 83.21)';
    }
    return null;
  }

  String? _validateWeightJourney() {
    final target = double.tryParse(
        _targetWeightController.text.trim().replaceAll(',', '.'));
    if (target == null || target < 20 || target > 500) {
      return 'Informe o peso alvo em kg (ex.: 75.0)';
    }
    return null;
  }

  Future<void> _continue() async {
    if (_busy) return;

    final err = _validateCurrent();
    if (err != null) {
      setState(() => _errorMessage = err);
      _shake();
      return;
    }
    setState(() => _errorMessage = null);

    if (!_isLastStep) {
      setState(() => _step = _OnboardingStep.values[_stepIndex + 1]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_step == _OnboardingStep.bodyMetrics) _ageFocus.requestFocus();
        if (_step == _OnboardingStep.weightJourney) {
          _targetWeightFocus.requestFocus();
        }
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final heightMeters =
        double.parse(_heightController.text.trim().replaceAll(',', '.'));
    final currentWeight = double.parse(
        _weightController.text.trim().replaceAll(',', '.'));
    final targetWeight = double.parse(
        _targetWeightController.text.trim().replaceAll(',', '.'));

    final seed = widget.seedProfile;
    if (seed != null) {
      final result = await ProfileApiService.recalculateDailyGoals(
        goal: _goal!,
        gender: _gender!,
        age: int.parse(_ageController.text.trim()),
        height: (heightMeters * 100).round(),
        weight: currentWeight.round(),
        startingWeight: seed.startingWeight,
        targetWeight: targetWeight.round(),
        activityLevel: _activityLevel!,
        dailyRoutineLevel: _dailyRoutineLevel!,
        goalIntensity: _goalIntensity!,
      );

      if (!mounted) return;
      setState(() => _busy = false);

      if (result.ok) {
        await AppHaptics.success();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          AppTransitions.fade(
            page: GoalsResultScreen(
              initialGoals: result.goals,
              finishWithPop: true,
              afterFinish: widget.onRecalculateDone,
            ),
          ),
        );
        return;
      }

      await AppHaptics.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error ?? 'Não foi possível recalcular suas metas.',
          ),
        ),
      );
      return;
    }

    final result = await OnboardingApiService.submit(
      goal: _goal!,
      gender: _gender!,
      age: int.parse(_ageController.text.trim()),
      height: heightMeters * 100,
      weight: currentWeight,
      startingWeight: currentWeight,
      targetWeight: targetWeight,
      activityLevel: _activityLevel!,
      dailyRoutineLevel: _dailyRoutineLevel!,
      goalIntensity: _goalIntensity!,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (result.ok) {
      await AppHaptics.success();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        AppTransitions.fade(page: const GoalsResultScreen()),
      );
      return;
    }

    await AppHaptics.error();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Não foi possível salvar seu perfil.'),
      ),
    );
  }

  void _selectGoal(int value) {
    if (_busy) return;
    AppHaptics.selection();
    setState(() {
      _goal = value;
      _errorMessage = null;
    });
  }

  void _selectGender(int value) {
    if (_busy) return;
    AppHaptics.selection();
    setState(() {
      _gender = value;
      _errorMessage = null;
    });
  }

  void _selectDailyRoutineLevel(int value) {
    if (_busy) return;
    AppHaptics.selection();
    setState(() {
      _dailyRoutineLevel = value;
      _errorMessage = null;
    });
  }

  void _selectGoalIntensity(int value) {
    if (_busy) return;
    AppHaptics.selection();
    setState(() {
      _goalIntensity = value;
      _errorMessage = null;
    });
  }

  void _back() {
    if (_busy) return;
    if (_stepIndex == 0 && widget.seedProfile != null) {
      Navigator.of(context).pop();
      return;
    }
    if (_stepIndex > 0) {
      setState(() {
        _errorMessage = null;
        _step = _OnboardingStep.values[_stepIndex - 1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              stepIndex: _stepIndex,
              stepCount: _stepCount,
              showBack: _stepIndex > 0,
              onBack: _back,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset =
                      math.sin(_shakeController.value * math.pi * 4) * 7.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: AnimatedSwitcher(
                  duration: MotionTokens.medium,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildStepContent(key: ValueKey(_step)),
                ),
              ),
            ),
            _BottomButton(
              busy: _busy,
              isLast: _isLastStep,
              onContinue: _continue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent({required Key key}) {
    return switch (_step) {
      _OnboardingStep.goal => _GoalStep(
          key: key,
          selected: _goal,
          onSelect: _selectGoal,
          errorMessage: _errorMessage,
        ),
      _OnboardingStep.gender => _GenderStep(
          key: key,
          selected: _gender,
          onSelect: _selectGender,
          errorMessage: _errorMessage,
        ),
      _OnboardingStep.bodyMetrics => _BodyMetricsStep(
          key: key,
          ageController: _ageController,
          heightController: _heightController,
          weightController: _weightController,
          ageFocus: _ageFocus,
          heightFocus: _heightFocus,
          weightFocus: _weightFocus,
          busy: _busy,
          errorMessage: _errorMessage,
          onSubmit: _continue,
        ),
      _OnboardingStep.weightJourney => _WeightJourneyStep(
          key: key,
          targetWeightController: _targetWeightController,
          targetWeightFocus: _targetWeightFocus,
          busy: _busy,
          errorMessage: _errorMessage,
          onSubmit: _continue,
        ),
      _OnboardingStep.dailyRoutineLevel => _DailyRoutineStep(
          key: key,
          selected: _dailyRoutineLevel,
          onSelect: _selectDailyRoutineLevel,
          errorMessage: _errorMessage,
        ),
      _OnboardingStep.activityLevel => _ActivityLevelStep(
          key: key,
          selected: _activityLevel,
          onSelect: (v) {
            AppHaptics.selection();
            setState(() {
              _activityLevel = v;
              _errorMessage = null;
            });
          },
          errorMessage: _errorMessage,
        ),
      _OnboardingStep.goalIntensity => _GoalIntensityStep(
          key: key,
          selected: _goalIntensity,
          onSelect: _selectGoalIntensity,
          errorMessage: _errorMessage,
        ),
    };
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.stepIndex,
    required this.stepCount,
    required this.showBack,
    required this.onBack,
  });

  final int stepIndex;
  final int stepCount;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: showBack ? 1.0 : 0.0,
            duration: MotionTokens.fast,
            child: IconButton(
              onPressed: showBack ? onBack : null,
              icon: const Icon(AppIcons.caretLeft),
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 1 / stepCount,
                end: (stepIndex + 1) / stepCount,
              ),
              duration: MotionTokens.medium,
              curve: MotionTokens.enter,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    backgroundColor: AppColors.borderDefault,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primaryGreen),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom button ────────────────────────────────────────────────────────────

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.busy,
    required this.isLast,
    required this.onContinue,
  });

  final bool busy;
  final bool isLast;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: busy ? null : onContinue,
          child: busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.buttonText,
                  ),
                )
              : Text(isLast ? 'Concluir' : 'Continuar'),
        ),
      ),
    );
  }
}

// ─── Step header ──────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Selection card (grid) ────────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelect,
  });

  final int value;
  final String label;
  final IconData icon;
  final int? selected;
  final ValueChanged<int> onSelect;

  bool get _active => selected == value;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        curve: MotionTokens.enter,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _active
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _active ? AppColors.primaryGreen : AppColors.borderDefault,
            width: _active ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: _active ? AppColors.primaryGreen : AppColors.iconDefault,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        _active ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selection tile (list) ────────────────────────────────────────────────────

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.onSelect,
  });

  final int value;
  final String label;
  final String sublabel;
  final IconData icon;
  final int? selected;
  final ValueChanged<int> onSelect;

  bool get _active => selected == value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        curve: MotionTokens.enter,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _active
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _active ? AppColors.primaryGreen : AppColors.borderDefault,
            width: _active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: _active ? AppColors.primaryGreen : AppColors.iconDefault,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          _active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: _active ? 1.0 : 0.0,
              duration: MotionTokens.fast,
              child: const Icon(
                AppIcons.checkCircle,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error message ────────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
      ),
    );
  }
}

// ─── Step 1: Goal ─────────────────────────────────────────────────────────────

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    super.key,
    required this.selected,
    required this.onSelect,
    this.errorMessage,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _StepHeader(
            title: 'Qual é o seu\nobjetivo?',
            subtitle: 'Personalizamos sua experiência para você.',
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              _SelectionCard(
                value: 1,
                label: 'Perder peso',
                icon: AppIcons.trendDown,
                selected: selected,
                onSelect: onSelect,
              ),
              _SelectionCard(
                value: 2,
                label: 'Ganhar músculo',
                icon: AppIcons.barbell,
                selected: selected,
                onSelect: onSelect,
              ),
              _SelectionCard(
                value: 3,
                label: 'Manter peso',
                icon: AppIcons.scales,
                selected: selected,
                onSelect: onSelect,
              ),
              _SelectionCard(
                value: 4,
                label: 'Recomposição corporal',
                icon: AppIcons.arrowsClockwise,
                selected: selected,
                onSelect: onSelect,
              ),
            ],
          ),
          if (errorMessage != null) _ErrorText(errorMessage!),
        ],
      ),
    );
  }
}

// ─── Step 2: Gender ───────────────────────────────────────────────────────────

class _GenderStep extends StatelessWidget {
  const _GenderStep({
    super.key,
    required this.selected,
    required this.onSelect,
    this.errorMessage,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _StepHeader(
            title: 'Qual é o seu\nsexo biológico?',
            subtitle: 'Usado para calcular suas necessidades calóricas.',
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _SelectionCard(
                value: 1,
                label: 'Masculino',
                icon: AppIcons.genderMale,
                selected: selected,
                onSelect: onSelect,
              ),
              _SelectionCard(
                value: 2,
                label: 'Feminino',
                icon: AppIcons.genderFemale,
                selected: selected,
                onSelect: onSelect,
              ),
              _SelectionCard(
                value: 3,
                label: 'Outro',
                icon: AppIcons.genderIntersex,
                selected: selected,
                onSelect: onSelect,
              ),
            ],
          ),
          if (errorMessage != null) _ErrorText(errorMessage!),
        ],
      ),
    );
  }
}

// ─── Step 3: Body metrics ─────────────────────────────────────────────────────

class _BodyMetricsStep extends StatelessWidget {
  const _BodyMetricsStep({
    super.key,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.ageFocus,
    required this.heightFocus,
    required this.weightFocus,
    required this.busy,
    required this.onSubmit,
    this.errorMessage,
  });

  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final FocusNode ageFocus;
  final FocusNode heightFocus;
  final FocusNode weightFocus;
  final bool busy;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _StepHeader(
            title: 'Suas medidas\ncorporais',
            subtitle: 'Ajuda a calcular seu gasto calórico diário.',
          ),
          const SizedBox(height: 32),
          TextField(
            controller: ageController,
            focusNode: ageFocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: !busy,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              labelText: 'Idade',
              hintText: 'Ex.: 24',
              suffixText: 'anos',
            ),
            onSubmitted: (_) => heightFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: heightController,
            focusNode: heightFocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: !busy,
            inputFormatters: [
              AutoDecimalFormatter(
                integerDigits: 1,
                decimalDigits: 2,
                separator: ',',
              ),
            ],
            decoration: const InputDecoration(
              labelText: 'Altura',
              hintText: 'Ex.: 1,80',
              suffixText: 'm',
            ),
            onSubmitted: (_) => weightFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightController,
            focusNode: weightFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            enabled: !busy,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Peso atual',
              hintText: 'Ex.: 81.32 ou 110',
              suffixText: 'kg',
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          if (errorMessage != null) _ErrorText(errorMessage!),
        ],
      ),
    );
  }
}

// ─── Step 4: Weight journey ───────────────────────────────────────────────────

class _WeightJourneyStep extends StatelessWidget {
  const _WeightJourneyStep({
    super.key,
    required this.targetWeightController,
    required this.targetWeightFocus,
    required this.busy,
    required this.onSubmit,
    this.errorMessage,
  });

  final TextEditingController targetWeightController;
  final FocusNode targetWeightFocus;
  final bool busy;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _StepHeader(
            title: 'Qual é seu\nobjetivo de peso?',
            subtitle: 'O peso que você quer alcançar.',
          ),
          const SizedBox(height: 32),
          TextField(
            controller: targetWeightController,
            focusNode: targetWeightFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            enabled: !busy,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Peso alvo',
              hintText: 'Ex.: 75 ou 75.5',
              suffixText: 'kg',
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          if (errorMessage != null) _ErrorText(errorMessage!),
        ],
      ),
    );
  }
}

// ─── Step 5: Activity level ───────────────────────────────────────────────────

class _ActivityLevelStep extends StatelessWidget {
  const _ActivityLevelStep({
    super.key,
    required this.selected,
    required this.onSelect,
    this.errorMessage,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _StepHeader(
            title: 'Nível de\natividade',
            subtitle: 'Com que frequência você se exercita?',
          ),
          const SizedBox(height: 28),
          _SelectionTile(
            value: 1,
            label: 'Sedentário',
            sublabel: 'Pouco ou nenhum exercício',
            icon: AppIcons.couch,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _SelectionTile(
            value: 2,
            label: 'Levemente ativo',
            sublabel: '1–3 dias de exercício por semana',
            icon: AppIcons.personSimpleWalk,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _SelectionTile(
            value: 3,
            label: 'Moderadamente ativo',
            sublabel: '3–5 dias de exercício por semana',
            icon: AppIcons.personSimpleRun,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _SelectionTile(
            value: 4,
            label: 'Muito ativo',
            sublabel: '6–7 dias de exercício por semana',
            icon: AppIcons.basketball,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _SelectionTile(
            value: 5,
            label: 'Atleta',
            sublabel: 'Exercício intenso diário',
            icon: AppIcons.trophy,
            selected: selected,
            onSelect: onSelect,
          ),
          if (errorMessage != null) _ErrorText(errorMessage!),
        ],
      ),
    );
  }
}

// ─── Rich selection card (title + description + optional bullets) ───────────

class _RichSelectionCard extends StatelessWidget {
  const _RichSelectionCard({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onSelect,
    this.bullets,
  });

  final int value;
  final String title;
  final String description;
  final IconData icon;
  final int? selected;
  final ValueChanged<int> onSelect;
  final List<String>? bullets;

  bool get _active => selected == value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        curve: MotionTokens.enter,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _active
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _active ? AppColors.primaryGreen : AppColors.borderDefault,
            width: _active ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _active
                    ? AppColors.primaryGreen.withValues(alpha: 0.15)
                    : AppColors.cardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    _active ? AppColors.primaryGreen : AppColors.iconDefault,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: _active ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (bullets != null && bullets!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...bullets!.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textDisabled,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                b,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              opacity: _active ? 1.0 : 0.0,
              duration: MotionTokens.fast,
              child: const Icon(
                AppIcons.checkCircle,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step: Daily routine ──────────────────────────────────────────────────────

class _DailyRoutineStep extends StatelessWidget {
  const _DailyRoutineStep({
    super.key,
    required this.selected,
    required this.onSelect,
    this.errorMessage,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _StepHeader(
            title: 'Como é sua rotina\ndurante o dia?',
            subtitle: 'Independente dos seus treinos.',
          ),
          const SizedBox(height: 28),
          _RichSelectionCard(
            value: 1,
            title: 'Maioria do tempo sentado',
            description: 'Pouca movimentação ao longo do dia.',
            icon: AppIcons.seat,
            selected: selected,
            onSelect: onSelect,
            bullets: const ['Escritório', 'Home office', 'Estudo'],
          ),
          const SizedBox(height: 10),
          _RichSelectionCard(
            value: 2,
            title: 'Caminho e me movimento algumas vezes',
            description:
                'Levanto com frequência ou faço pequenos deslocamentos.',
            icon: AppIcons.personSimpleWalk,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _RichSelectionCard(
            value: 3,
            title: 'Passo boa parte do dia em pé',
            description:
                'Trabalho ou rotina exige ficar em pé constantemente.',
            icon: AppIcons.path,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _RichSelectionCard(
            value: 4,
            title: 'Faço esforço físico frequentemente',
            description: 'Atividades físicas exigentes como parte do dia.',
            icon: AppIcons.hardHat,
            selected: selected,
            onSelect: onSelect,
          ),
          if (errorMessage != null) _ErrorText(errorMessage!),
        ],
      ),
    );
  }
}

// ─── Step: Goal intensity ─────────────────────────────────────────────────────

class _GoalIntensityStep extends StatelessWidget {
  const _GoalIntensityStep({
    super.key,
    required this.selected,
    required this.onSelect,
    this.errorMessage,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _StepHeader(
            title: 'Qual ritmo você\nprefere seguir?',
            subtitle: 'Isso ajusta a intensidade do seu plano.',
          ),
          const SizedBox(height: 28),
          _RichSelectionCard(
            value: 1,
            title: 'Leve e sustentável',
            description: 'Mudanças graduais e mais fáceis de manter.',
            icon: AppIcons.leaf,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _RichSelectionCard(
            value: 2,
            title: 'Equilibrado',
            description: 'Bom progresso mantendo equilíbrio.',
            icon: AppIcons.scales,
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 10),
          _RichSelectionCard(
            value: 3,
            title: 'Mais intenso',
            description: 'Resultados mais rápidos com maior disciplina.',
            icon: AppIcons.flame,
            selected: selected,
            onSelect: onSelect,
          ),
          if (errorMessage != null) _ErrorText(errorMessage!),
        ],
      ),
    );
  }
}
