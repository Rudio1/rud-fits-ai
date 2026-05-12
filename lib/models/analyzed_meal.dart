class AnalyzedFood {
  AnalyzedFood({
    required this.name,
    required this.estimatedQuantityGrams,
    this.foodId,
    this.caloriesKcal,
    this.carbohydratesGrams,
    this.fatGrams,
    this.proteinGrams,
  });

  String name;
  int estimatedQuantityGrams;
  String? foodId;
  double? caloriesKcal;
  double? carbohydratesGrams;
  double? fatGrams;
  double? proteinGrams;

  factory AnalyzedFood.fromJson(Map<String, dynamic> json) {
    return AnalyzedFood(
      name: (json['name'] as String?)?.trim() ?? '',
      estimatedQuantityGrams:
          (json['estimatedQuantityGrams'] as num?)?.round() ?? 0,
      foodId: json['foodId'] as String?,
      caloriesKcal: (json['caloriesKcal'] as num?)?.toDouble(),
      carbohydratesGrams: (json['carbohydratesGrams'] as num?)?.toDouble(),
      fatGrams: (json['fatGrams'] as num?)?.toDouble(),
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toEstimateRequestJson() => {
        'name': name,
        'estimatedQuantityGrams': estimatedQuantityGrams,
      };

  Map<String, dynamic> toJson() => {
        'name': name,
        'estimatedQuantityGrams': estimatedQuantityGrams,
        if (foodId != null) 'foodId': foodId,
        if (caloriesKcal != null) 'caloriesKcal': caloriesKcal,
        if (carbohydratesGrams != null) 'carbohydratesGrams': carbohydratesGrams,
        if (fatGrams != null) 'fatGrams': fatGrams,
        if (proteinGrams != null) 'proteinGrams': proteinGrams,
      };

  AnalyzedFood copy() => AnalyzedFood(
        name: name,
        estimatedQuantityGrams: estimatedQuantityGrams,
        foodId: foodId,
        caloriesKcal: caloriesKcal,
        carbohydratesGrams: carbohydratesGrams,
        fatGrams: fatGrams,
        proteinGrams: proteinGrams,
      );

  AnalyzedFood copyWithEdit({
    required String name,
    required int estimatedQuantityGrams,
  }) {
    final changed = name != this.name || estimatedQuantityGrams != this.estimatedQuantityGrams;
    if (changed) {
      return AnalyzedFood(
        name: name,
        estimatedQuantityGrams: estimatedQuantityGrams,
      );
    }
    return copy();
  }
}

class AnalyzedMeal {
  const AnalyzedMeal({required this.foods});

  final List<AnalyzedFood> foods;

  factory AnalyzedMeal.fromJson(Map<String, dynamic> json) {
    final raw = json['foods'] as List<dynamic>? ?? const [];
    return AnalyzedMeal(
      foods: raw
          .whereType<Map<String, dynamic>>()
          .map(AnalyzedFood.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toEstimateRequestJson() => {
        'foods': foods.map((f) => f.toEstimateRequestJson()).toList(),
      };
}
