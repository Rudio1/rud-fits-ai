import 'package:flutter/material.dart';

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

  IconData get icon => switch (this) {
        MealType.breakfast => Icons.free_breakfast_rounded,
        MealType.lunch => Icons.lunch_dining_rounded,
        MealType.dinner => Icons.dinner_dining_rounded,
        MealType.snack => Icons.cookie_rounded,
        MealType.preWorkout => Icons.bolt_rounded,
        MealType.postWorkout => Icons.fitness_center_rounded,
      };
}
