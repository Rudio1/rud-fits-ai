class DailyGoals {
  const DailyGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  factory DailyGoals.fromJson(Map<String, dynamic> json) {
    return DailyGoals(
      calories: json['dailyCaloriesGoal'] as int,
      protein: json['dailyProteinGoal'] as int,
      carbs: json['dailyCarbsGoal'] as int,
      fat: json['dailyFatGoal'] as int,
    );
  }
}
