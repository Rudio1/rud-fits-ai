class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.username,
    required this.profileImageUrl,
    required this.isActive,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    required this.dailyRoutineLevel,
    required this.goalIntensity,
    required this.startingWeight,
    required this.targetWeight,
  });

  final String userId;
  final String name;
  final String email;
  final String username;
  final String? profileImageUrl;
  final bool isActive;
  final int age;
  final int weight;
  final int height;
  final int gender;
  final int goal;
  final int activityLevel;
  final int dailyRoutineLevel;
  final int goalIntensity;
  final int startingWeight;
  final int targetWeight;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      age: (json['age'] as num?)?.round() ?? 0,
      weight: (json['weight'] as num?)?.round() ?? 0,
      height: (json['height'] as num?)?.round() ?? 0,
      gender: (json['gender'] as num?)?.round() ?? 0,
      goal: (json['goal'] as num?)?.round() ?? 0,
      activityLevel: (json['activityLevel'] as num?)?.round() ?? 0,
      dailyRoutineLevel: (json['dailyRoutineLevel'] as num?)?.round() ?? 0,
      goalIntensity: (json['goalIntensity'] as num?)?.round() ?? 0,
      startingWeight: (json['startingWeight'] as num?)?.round() ?? 0,
      targetWeight: (json['targetWeight'] as num?)?.round() ?? 0,
    );
  }
}

final class WeightProgressSnapshot {
  const WeightProgressSnapshot({
    required this.percentTowardTarget,
    required this.subtitle,
    this.barValue,
  });

  final int percentTowardTarget;
  final String subtitle;
  final double? barValue;
}

WeightProgressSnapshot weightProgressFor(UserProfile p) {
  final w = p.weight.toDouble();
  final s = p.startingWeight.toDouble();
  final t = p.targetWeight.toDouble();

  switch (p.goal) {
    case 1:
      final total = s - t;
      if (total <= 0) {
        return const WeightProgressSnapshot(
          percentTowardTarget: 0,
          subtitle: 'Ajuste peso inicial e alvo para acompanhar a evolução.',
          barValue: 0,
        );
      }
      final lost = s - w;
      final pct = ((lost / total) * 100).round().clamp(0, 100);
      final remain = w - t;
      final sub = remain <= 0
          ? 'Você atingiu (ou passou) o peso alvo. Parabéns pelo foco!'
          : 'Faltam cerca de ${remain.round()} kg para o alvo ($pct% do caminho).';
      return WeightProgressSnapshot(
        percentTowardTarget: pct,
        subtitle: sub,
        barValue: pct / 100.0,
      );
    case 2:
      final total = t - s;
      if (total <= 0) {
        return const WeightProgressSnapshot(
          percentTowardTarget: 0,
          subtitle: 'Ajuste peso inicial e alvo para acompanhar o ganho.',
          barValue: 0,
        );
      }
      final gained = w - s;
      final pct = ((gained / total) * 100).round().clamp(0, 100);
      final remain = t - w;
      final sub = remain <= 0
          ? 'Meta de peso para ganho atingida — continue nutrindo bem o treino.'
          : 'Faltam cerca de ${remain.round()} kg para o alvo ($pct% do caminho).';
      return WeightProgressSnapshot(
        percentTowardTarget: pct,
        subtitle: sub,
        barValue: pct / 100.0,
      );
    case 3:
      final diff = (w - t).abs();
      return WeightProgressSnapshot(
        percentTowardTarget: diff <= 2
            ? 100
            : (100 - (diff * 5).round()).clamp(0, 100),
        subtitle:
            'Objetivo: manter o peso perto de ${t.round()} kg. Hoje: ${w.round()} kg.',
        barValue: diff <= 2 ? 1.0 : (1.0 - (diff / 20).clamp(0.0, 0.95)),
      );
    case 4:
      if (t < s) {
        final total = s - t;
        if (total <= 0) {
          return const WeightProgressSnapshot(
            percentTowardTarget: 0,
            subtitle: 'Ajuste peso inicial e alvo para acompanhar a recomp.',
            barValue: 0,
          );
        }
        final lost = s - w;
        final pct = ((lost / total) * 100).round().clamp(0, 100);
        final remain = w - t;
        final sub = remain <= 0
            ? 'Você chegou no peso alvo da recomposição.'
            : 'Faltam cerca de ${remain.round()} kg no eixo definido ($pct% do trajeto).';
        return WeightProgressSnapshot(
          percentTowardTarget: pct,
          subtitle: sub,
          barValue: pct / 100.0,
        );
      }
      if (t > s) {
        final total = t - s;
        if (total <= 0) {
          return const WeightProgressSnapshot(
            percentTowardTarget: 0,
            subtitle: 'Ajuste os pesos para acompanhar a recomp.',
            barValue: 0,
          );
        }
        final gained = w - s;
        final pct = ((gained / total) * 100).round().clamp(0, 100);
        final remain = t - w;
        final sub = remain <= 0
            ? 'Você chegou no alvo da recomposição.'
            : 'Faltam cerca de ${remain.round()} kg ($pct% do trajeto).';
        return WeightProgressSnapshot(
          percentTowardTarget: pct,
          subtitle: sub,
          barValue: pct / 100.0,
        );
      }
      return WeightProgressSnapshot(
        percentTowardTarget: 50,
        subtitle:
            'Recomposição com peso inicial e alvo iguais — foque em medidas e treino.',
        barValue: 0.5,
      );
    default:
      return const WeightProgressSnapshot(
        percentTowardTarget: 0,
        subtitle: 'Defina seu objetivo no onboarding para ver o progresso aqui.',
        barValue: 0,
      );
  }
}
