import 'package:flutter/widgets.dart';

import 'package:rud_fits_ai/core/icons/app_icons.dart';

abstract final class ProfileLabels {
  static String gender(int v) => switch (v) {
        1 => 'Masculino',
        2 => 'Feminino',
        3 => 'Outro',
        _ => '—',
      };

  static String goal(int v) => switch (v) {
        1 => 'Perder peso',
        2 => 'Ganhar músculo',
        3 => 'Manter peso',
        4 => 'Recomposição corporal',
        _ => '—',
      };

  static String activityLevel(int v) => switch (v) {
        1 => 'Sedentário',
        2 => 'Levemente ativo',
        3 => 'Moderadamente ativo',
        4 => 'Muito ativo',
        5 => 'Atleta',
        _ => '—',
      };

  static String activityLevelDetail(int v) => switch (v) {
        1 => 'Pouco ou nenhum exercício',
        2 => '1–3 dias de exercício por semana',
        3 => '3–5 dias de exercício por semana',
        4 => '6–7 dias de exercício por semana',
        5 => 'Exercício intenso diário',
        _ => '',
      };

  static String dailyRoutine(int v) => switch (v) {
        1 => 'Maioria do tempo sentado',
        2 => 'Caminho e me movimento algumas vezes',
        3 => 'Passo boa parte do dia em pé',
        4 => 'Faço esforço físico frequentemente',
        _ => '—',
      };

  static String goalIntensity(int v) => switch (v) {
        1 => 'Leve e sustentável',
        2 => 'Equilibrado',
        3 => 'Mais intenso',
        _ => '—',
      };

  static String goalIntensityDetail(int v) => switch (v) {
        1 => 'Mudanças graduais e mais fáceis de manter',
        2 => 'Bom progresso mantendo equilíbrio',
        3 => 'Resultados mais rápidos com maior disciplina',
        _ => '',
      };

  static IconData goalIcon(int v) => switch (v) {
        1 => AppIcons.trendDown,
        2 => AppIcons.barbell,
        3 => AppIcons.scales,
        4 => AppIcons.arrowsClockwise,
        _ => AppIcons.info,
      };
}
