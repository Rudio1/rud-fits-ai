class SavedMealLog {
  const SavedMealLog({
    required this.id,
    required this.name,
    required this.mealType,
    required this.consumedAtUtc,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  final String id;
  final String name;
  final int mealType;
  final String consumedAtUtc;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  factory SavedMealLog.fromJson(Map<String, dynamic> json) {
    return SavedMealLog(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mealType: (json['mealType'] as num?)?.round() ?? 0,
      consumedAtUtc: json['consumedAtUtc'] as String? ?? '',
      totalCalories: (json['totalCalories'] as num?)?.round() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0,
    );
  }
}
