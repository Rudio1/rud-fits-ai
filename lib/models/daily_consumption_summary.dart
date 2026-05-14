class DailyConsumptionSummary {
  const DailyConsumptionSummary({
    required this.date,
    required this.mealsCount,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  final String date;
  final int mealsCount;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  factory DailyConsumptionSummary.fromJson(Map<String, dynamic> json) {
    return DailyConsumptionSummary(
      date: (json['date'] as String?)?.trim() ?? '',
      mealsCount: (json['mealsCount'] as num?)?.round() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.round() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0,
    );
  }
}
