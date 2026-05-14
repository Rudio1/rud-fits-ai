import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/animations/motion_tokens.dart';
import 'package:rud_fits_ai/core/auth_session.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/auth/screens/register_screen.dart';
import 'package:rud_fits_ai/features/onboarding/screens/onboarding_screen.dart';
import 'package:rud_fits_ai/features/shell/main_shell_screen.dart';
import 'package:rud_fits_ai/services/auth_api_service.dart';
import 'package:rud_fits_ai/themes/themes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: MotionTokens.slow,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: MotionTokens.enter,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: MotionTokens.enter,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openRegister() async {
    final registered = await Navigator.of(
      context,
    ).push<bool>(AppTransitions.slideFromRight(page: const RegisterScreen()));
    if (!mounted || registered != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conta criada. Entre com seu e-mail e senha.'),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = await AuthApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      final token = result.body?['accessToken'] as String?;
      if (token != null) AuthSession.setToken(token);
      AuthSession.setUsername(result.body?['username'] as String?);
      final isFirstAccess = result.body?['isFirstAccess'] as bool? ?? false;

      await AppHaptics.success();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        AppTransitions.fade(
          page: isFirstAccess
              ? const OnboardingScreen()
              : const MainShellScreen(),
        ),
      );
      return;
    }

    await AppHaptics.error();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Não foi possível entrar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.14),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.aiBlue.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.aiBlue.withValues(alpha: 0.08),
                    blurRadius: 80,
                    spreadRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: SizedBox(
                                height: 270,
                                child: OverflowBox(
                                  maxWidth: 860,
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'public/images/Logo.png',
                                    width: 860,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entre na sua conta e continue acompanhando suas refeições, calorias e macros.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.borderDefault,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.background.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Bem-vindo de volta',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Use seu e-mail e senha para acessar o app.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    enabled: !_loading,
                                    decoration: const InputDecoration(
                                      labelText: 'E-mail',
                                      hintText: 'seu@email.com',
                                    ),
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty) return 'Informe o e-mail';
                                      if (!v.contains('@') ||
                                          !v.contains('.')) {
                                        return 'E-mail inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    enabled: !_loading,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: 'Senha',
                                      suffixIcon: IconButton(
                                        onPressed: _loading
                                            ? null
                                            : () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? AppIcons.eye
                                              : AppIcons.eyeSlash,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      final v = value ?? '';
                                      if (v.isEmpty) {
                                        return 'Informe a senha';
                                      }
                                      if (v.length < 6) {
                                        return 'Mínimo de 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(60),
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.buttonText,
                                            ),
                                          )
                                        : const Text('Entrar'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Ainda não tem conta? ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loading ? null : _openRegister,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Registre-se'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
