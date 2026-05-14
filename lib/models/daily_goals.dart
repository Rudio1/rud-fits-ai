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
    int n(String key) => (json[key] as num).round();

    return DailyGoals(
      calories: n('dailyCaloriesGoal'),
      protein: n('dailyProteinGoal'),
      carbs: n('dailyCarbsGoal'),
      fat: n('dailyFatGoal'),
    );
  }
}
