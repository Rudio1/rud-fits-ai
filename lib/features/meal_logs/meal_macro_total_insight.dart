final class MealMacroPraise {
  const MealMacroPraise({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  static MealMacroPraise? fromGrams({
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    final kP = proteinG * 4.0;
    final kC = carbsG * 4.0;
    final kF = fatG * 9.0;
    final total = kP + kC + kF;
    if (total < 1.0) return null;

    final pPct = ((kP / total) * 100).round().clamp(0, 100);
    final cPct = ((kC / total) * 100).round().clamp(0, 100);
    final fPct = ((kF / total) * 100).round().clamp(0, 100);

    final pair = _messageFor(pPct: pPct, cPct: cPct, fPct: fPct);
    return MealMacroPraise(title: pair.$1, subtitle: pair.$2);
  }
}

(String, String) _messageFor({
  required int pPct,
  required int cPct,
  required int fPct,
}) {
  if (pPct >= 30) {
    if (cPct >= 35) {
      return (
        'Você caprichou na proteína — e no equilíbrio!',
        'Essa combinação com carboidrato mostra cuidado: ajuda na recuperação e repõe energia com carinho. Orgulho do seu esforço.'
      );
    }
    if (fPct >= 26) {
      return (
        'Que bela escolha de proteína e saciedade!',
        'Você montou uma refeição que sustenta e faz bem: proteína em destaque e gorduras que completam o prato com inteligência.'
      );
    }
    return (
      'Mandou muito bem na proteína!',
      'Sua refeição tem uma base ótima para o corpo e a energia ficou bem distribuída. Parabéns por se priorizar assim.'
    );
  }

  if (cPct >= 43 && pPct < 28) {
    return (
      'Energia de sobra para o seu dia!',
      'Você optou por uma refeição bem carboidratada — perfeita para treinar, estudar ou seguir firme. Continue confiando no seu ritmo.'
    );
  }

  if (fPct >= 28 && pPct >= 24 && cPct <= 40 && pPct < 30) {
    return (
      'Refeição que abraça e sustenta!',
      'Você equilibrou proteína e gordura com bom senso — é um jeito ótimo de se sentir satisfeito e bem nutrido.'
    );
  }

  if (pPct >= 18 && cPct >= 18 && fPct >= 18 && pPct <= 42 && cPct <= 45 && fPct <= 42) {
    return (
      'Que equilíbrio lindo no prato!',
      'Você distribuiu os macros com atenção — isso mostra cuidado com você mesmo. Continue celebrando cada refeição.'
    );
  }

  if (fPct >= 38 && pPct < 28) {
    return (
      'Sabor e conforto com a sua cara!',
      'Você trouxe gorduras que dão corpo à refeição e ajudam na saciedade. Cada escolha consciente vale ouro no seu dia a dia.'
    );
  }

  return (
    'Obrigado por cuidar de você!',
    'Registrar refeições assim é um gesto de carinho com o seu corpo. Você está no caminho certo — siga com essa energia boa.'
  );
}
