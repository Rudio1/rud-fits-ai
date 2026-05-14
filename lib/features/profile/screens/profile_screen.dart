import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/animations/app_transitions.dart';
import 'package:rud_fits_ai/core/auth_session.dart';
import 'package:rud_fits_ai/core/haptics/app_haptics.dart';
import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/auth/screens/login_screen.dart';
import 'package:rud_fits_ai/features/onboarding/screens/onboarding_screen.dart';
import 'package:rud_fits_ai/features/profile/profile_labels.dart';
import 'package:rud_fits_ai/models/user_profile.dart';
import 'package:rud_fits_ai/services/profile_api_service.dart';
import 'package:rud_fits_ai/themes/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ProfileApiService.fetchMe();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _profile = result.profile;
        _error = null;
      } else {
        _profile = null;
        _error = result.error;
      }
    });
  }

  Future<void> _pullRefresh() async {
    final result = await ProfileApiService.fetchMe();
    if (!mounted) return;
    setState(() {
      if (result.ok) {
        _profile = result.profile;
        _error = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Não foi possível atualizar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  void _openRecalculateFlow() {
    final p = _profile;
    if (p == null) return;
    AppHaptics.selection();
    Navigator.of(context).push(
      AppTransitions.fade(
        page: OnboardingScreen(
          seedProfile: p,
          onRecalculateDone: () {
            if (mounted) _fetch();
          },
        ),
      ),
    );
  }

  double? _bmi(UserProfile p) {
    if (p.height <= 0 || p.weight <= 0) return null;
    final hM = p.height / 100.0;
    return p.weight / (hM * hM);
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Abaixo do esperado';
    if (bmi < 25) return 'Faixa usual';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  IconData _genderIcon(int g) => switch (g) {
        1 => AppIcons.genderMale,
        2 => AppIcons.genderFemale,
        _ => AppIcons.genderIntersex,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(AppIcons.signOut),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _error != null
              ? _ProfileError(
                  message: _error!,
                  onRetry: _fetch,
                )
              : _profile == null
                  ? _ProfileError(
                      message: 'Perfil indisponível.',
                      onRetry: _fetch,
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryGreen,
                      onRefresh: _pullRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          _ProfileHero(
                            profile: _profile!,
                            genderIcon: _genderIcon(_profile!.gender),
                          ),
                          const SizedBox(height: 20),
                          _SectionTitle('Corpo e dados'),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  _MetricGrid(
                                    items: [
                                      _MetricChip(
                                        label: 'Idade',
                                        value: '${_profile!.age} anos',
                                        icon: AppIcons.calendar,
                                      ),
                                      _MetricChip(
                                        label: 'Peso',
                                        value: '${_profile!.weight} kg',
                                        icon: AppIcons.scales,
                                      ),
                                      _MetricChip(
                                        label: 'Altura',
                                        value: '${_profile!.height} cm',
                                        icon: AppIcons.path,
                                      ),
                                      _MetricChip(
                                        label: 'Gênero',
                                        value:
                                            ProfileLabels.gender(_profile!.gender),
                                        icon: _genderIcon(_profile!.gender),
                                      ),
                                    ],
                                  ),
                                  if (_bmi(_profile!) != null) ...[
                                    const Divider(height: 28),
                                    Row(
                                      children: [
                                        Icon(
                                          AppIcons.chartLine,
                                          size: 22,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'IMC',
                                                style: textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                '${_bmi(_profile!)!.toStringAsFixed(1)} · ${_bmiLabel(_bmi(_profile!)!)}',
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _SectionTitle('Objetivo e estilo de vida'),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundSecondary,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.borderDefault,
                                          ),
                                        ),
                                        child: Icon(
                                          ProfileLabels.goalIcon(
                                              _profile!.goal),
                                          color: AppColors.primaryGreen,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ProfileLabels.goal(
                                                  _profile!.goal),
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Intensidade: ${ProfileLabels.goalIntensity(_profile!.goalIntensity)}',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if (ProfileLabels.goalIntensityDetail(
                                                    _profile!.goalIntensity)
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Text(
                                                  ProfileLabels
                                                      .goalIntensityDetail(
                                                          _profile!
                                                              .goalIntensity),
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    color:
                                                        AppColors.textDisabled,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _BulletLabel(
                                    icon: AppIcons.personSimpleRun,
                                    title: 'Nível de atividade',
                                    subtitle: ProfileLabels.activityLevel(
                                        _profile!.activityLevel),
                                    detail: ProfileLabels.activityLevelDetail(
                                        _profile!.activityLevel),
                                  ),
                                  const SizedBox(height: 12),
                                  _BulletLabel(
                                    icon: AppIcons.hardHat,
                                    title: 'Rotina do dia a dia',
                                    subtitle: ProfileLabels.dailyRoutine(
                                        _profile!.dailyRoutineLevel),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _SectionTitle('Metas e progresso de peso'),
                          const SizedBox(height: 10),
                          _WeightProgressCard(profile: _profile!),
                          const SizedBox(height: 22),
                          _SectionTitle('Metas diárias'),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Revise objetivo, medidas e hábitos como no cadastro. Ao concluir, suas calorias e macros do dia serão recalculados no servidor.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.tonalIcon(
                                    onPressed: _openRecalculateFlow,
                                    icon: const Icon(AppIcons.arrowsClockwise),
                                    label: const Text('Recalcular metas'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _SectionTitle('Conta'),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile!.email,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '@${_profile!.username}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      _StatusPill(
                                        label: _profile!.isActive
                                            ? 'Conta ativa'
                                            : 'Conta inativa',
                                        positive: _profile!.isActive,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${_profile!.userId}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.textDisabled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.genderIcon,
  });

  final UserProfile profile;
  final IconData genderIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final url = profile.profileImageUrl?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(url: url, fallbackIcon: genderIcon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name.isEmpty ? 'Sem nome' : profile.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fallbackIcon});

  final String? url;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.backgroundSecondary,
        child: Icon(
          fallbackIcon,
          size: 34,
          color: AppColors.textSecondary,
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.backgroundSecondary,
          child: Icon(
            fallbackIcon,
            size: 34,
            color: AppColors.textSecondary,
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final first = items[i];
      final second = i + 1 < items.length
          ? items[i + 1]
          : const SizedBox.shrink();
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < items.length ? 10 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 10),
              Expanded(child: second),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.iconDefault),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLabel extends StatelessWidget {
  const _BulletLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.iconDefault),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail != null && detail!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    detail!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightProgressCard extends StatelessWidget {
  const _WeightProgressCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final snap = weightProgressFor(profile);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _WeightMilestone(
                    label: 'Início',
                    value: '${profile.startingWeight} kg',
                  ),
                ),
                Expanded(
                  child: _WeightMilestone(
                    label: 'Atual',
                    value: '${profile.weight} kg',
                    emphasize: true,
                  ),
                ),
                Expanded(
                  child: _WeightMilestone(
                    label: 'Meta',
                    value: '${profile.targetWeight} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (snap.barValue != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: snap.barValue!.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.backgroundSecondary,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${snap.percentTowardTarget}% do trajeto estimado',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              snap.subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightMilestone extends StatelessWidget {
  const _WeightMilestone({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: (emphasize ? textTheme.titleMedium : textTheme.titleSmall)
              ?.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasize ? AppColors.primaryGreen : null,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final bg = positive
        ? AppColors.primaryGreen.withValues(alpha: 0.18)
        : AppColors.warning.withValues(alpha: 0.18);
    final fg =
        positive ? AppColors.lightGreen : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: positive
              ? AppColors.primaryGreen.withValues(alpha: 0.45)
              : AppColors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? AppIcons.checkCircle : AppIcons.info,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(
          AppIcons.wifiSlash,
          size: 48,
          color: AppColors.textDisabled,
        ),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.arrowClockwise),
            label: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}
