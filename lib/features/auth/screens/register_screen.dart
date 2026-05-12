import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/services/auth_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';

enum _RegisterStep { fullName, email, password, username }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  _RegisterStep _step = _RegisterStep.fullName;
  String? _fieldError;
  bool _busy = false;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _usernameFocus = FocusNode();

  bool _obscurePassword = true;

  late final AnimationController _shakeController;

  int get _stepIndex => _step.index;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: MotionTokens.normal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusForStep(_step);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  void _focusForStep(_RegisterStep step) {
    final node = switch (step) {
      _RegisterStep.fullName => _fullNameFocus,
      _RegisterStep.email => _emailFocus,
      _RegisterStep.password => _passwordFocus,
      _RegisterStep.username => _usernameFocus,
    };
    node.requestFocus();
  }

  void _scheduleFocus(_RegisterStep step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusForStep(step);
    });
  }

  Future<void> _shake() async {
    await _shakeController.forward(from: 0);
    _shakeController.reset();
  }

  String? _validateFullName() {
    final v = _fullNameController.text.trim();
    if (v.isEmpty) return 'Informe seu nome completo';
    if (v.length < 3) return 'Nome completo muito curto';
    return null;
  }

  String? _validateEmail() {
    final v = _emailController.text.trim();
    if (v.isEmpty) return 'Informe seu e-mail';
    if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
    return null;
  }

  String? _validatePassword() {
    final v = _passwordController.text;
    if (v.isEmpty) return 'Crie uma senha';
    if (v.length < 6) return 'Mínimo de 6 caracteres';
    return null;
  }

  String? _validateUsername() {
    final v = _usernameController.text.trim();
    if (v.isEmpty) return 'Como devemos te chamar?';
    if (v.length < 2) return 'Muito curto';
    return null;
  }

  String? _validateCurrent() {
    return switch (_step) {
      _RegisterStep.fullName => _validateFullName(),
      _RegisterStep.email => _validateEmail(),
      _RegisterStep.password => _validatePassword(),
      _RegisterStep.username => _validateUsername(),
    };
  }

  Future<void> _continue() async {
    if (_busy) return;

    final err = _validateCurrent();
    if (err != null) {
      setState(() => _fieldError = err);
      _shake();
      return;
    }
    setState(() => _fieldError = null);

    if (_step != _RegisterStep.username) {
      setState(() {
        _step = _RegisterStep.values[_stepIndex + 1];
      });
      _scheduleFocus(_step);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final result = await AuthApiService.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (result.ok) {
      await AppHaptics.success();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    await AppHaptics.error();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Não foi possível criar a conta.')),
    );
  }

  void _back() {
    if (_busy) return;
    if (_stepIndex > 0) {
      setState(() {
        _fieldError = null;
        _step = _RegisterStep.values[_stepIndex - 1];
      });
      _scheduleFocus(_step);
    } else {
      Navigator.of(context).pop();
    }
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
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset = math.sin(_shakeController.value * math.pi * 4) * 7.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: AnimatedSwitcher(
                              duration: MotionTokens.medium,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _StepContent(
                                key: ValueKey(_step),
                                step: _step,
                                theme: theme,
                                busy: _busy,
                                fullNameController: _fullNameController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                usernameController: _usernameController,
                                fullNameFocus: _fullNameFocus,
                                emailFocus: _emailFocus,
                                passwordFocus: _passwordFocus,
                                usernameFocus: _usernameFocus,
                                obscurePassword: _obscurePassword,
                                onTogglePassword: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                                fieldError: _fieldError,
                                onContinue: _continue,
                                stepIndex: _stepIndex,
                                stepCount: _RegisterStep.values.length,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    super.key,
    required this.step,
    required this.theme,
    required this.busy,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.usernameController,
    required this.fullNameFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.usernameFocus,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.fieldError,
    required this.onContinue,
    required this.stepIndex,
    required this.stepCount,
  });

  final _RegisterStep step;
  final ThemeData theme;
  final bool busy;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final FocusNode fullNameFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final FocusNode usernameFocus;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String? fieldError;
  final Future<void> Function() onContinue;
  final int stepIndex;
  final int stepCount;

  String get _question {
    return switch (step) {
      _RegisterStep.fullName => 'Qual é o seu nome completo?',
      _RegisterStep.email => 'Qual é o seu e-mail?',
      _RegisterStep.password => 'Crie uma senha segura',
      _RegisterStep.username => 'Como podemos te chamar?',
    };
  }

  bool get _isLast => step == _RegisterStep.username;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(stepCount, (i) {
            final active = i <= stepIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: MotionTokens.normal,
                curve: MotionTokens.enter,
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? AppColors.primaryGreen : AppColors.borderDefault,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        Text(
          _question,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 32),
        switch (step) {
          _RegisterStep.fullName => TextField(
              controller: fullNameController,
              focusNode: fullNameFocus,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
              enabled: !busy,
              decoration: InputDecoration(
                hintText: 'Nome e sobrenome',
                errorText: fieldError,
              ),
              onSubmitted: (_) => onContinue(),
            ),
          _RegisterStep.email => TextField(
              controller: emailController,
              focusNode: emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
              enabled: !busy,
              decoration: InputDecoration(
                hintText: 'nome@email.com',
                errorText: fieldError,
              ),
              onSubmitted: (_) => onContinue(),
            ),
          _RegisterStep.password => TextField(
              controller: passwordController,
              focusNode: passwordFocus,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
              enabled: !busy,
              decoration: InputDecoration(
                hintText: 'Mínimo 6 caracteres',
                errorText: fieldError,
                suffixIcon: IconButton(
                  onPressed: busy ? null : onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => onContinue(),
            ),
          _RegisterStep.username => TextField(
              controller: usernameController,
              focusNode: usernameFocus,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
              enabled: !busy,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: InputDecoration(
                hintText: 'Ex.: Rudio',
                errorText: fieldError,
              ),
              onSubmitted: (_) => onContinue(),
            ),
        },
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: busy ? null : () => onContinue(),
          child: busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.buttonText,
                  ),
                )
              : Text(_isLast ? 'Criar conta' : 'Continuar'),
        ),
      ],
    );
  }
}
