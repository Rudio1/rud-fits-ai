enum MealType {
  breakfast(1, 'Café da manhã'),
  lunch(2, 'Almoço'),
  dinner(3, 'Jantar'),
  snack(4, 'Lanche'),
  preWorkout(5, 'Pré-treino'),
  postWorkout(6, 'Pós-treino');

  const MealType(this.apiValue, this.labelPt);

  final int apiValue;
  final String labelPt;

  String get pickerLeadingAssetPath => switch (this) {
        MealType.breakfast => 'public/images/cafe-da-manha.png',
        MealType.lunch => 'public/images/almoco.png',
        MealType.dinner => 'public/images/jantar.png',
        MealType.snack => 'public/images/lanche.png',
        MealType.preWorkout => 'public/images/pre-treino.png',
        MealType.postWorkout => 'public/images/pos-treino.png',
      };

  static MealType fromApiValue(int value) {
    for (final t in MealType.values) {
      if (t.apiValue == value) return t;
    }
    return MealType.snack;
  }
}
