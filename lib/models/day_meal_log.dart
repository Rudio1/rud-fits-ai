class DayMealLogItem {
  const DayMealLogItem({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unitType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String id;
  final String foodId;
  final String foodName;
  final int quantity;
  final int unitType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  DayMealLogItem copyWith({
    String? id,
    String? foodId,
    String? foodName,
    int? quantity,
    int? unitType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return DayMealLogItem(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      quantity: quantity ?? this.quantity,
      unitType: unitType ?? this.unitType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  factory DayMealLogItem.fromJson(Map<String, dynamic> json) {
    return DayMealLogItem(
      id: json['id'] as String? ?? '',
      foodId: json['foodId'] as String? ?? '',
      foodName: (json['foodName'] as String?)?.trim() ?? '',
      quantity: (json['quantity'] as num?)?.round() ?? 0,
      unitType: (json['unitType'] as num?)?.round() ?? 0,
      calories: (json['calories'] as num?)?.round() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DayMealLogEntry {
  const DayMealLogEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.sourceType,
    required this.consumedAtRaw,
    required this.notes,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.items,
  });

  final String id;
  final String name;
  final int mealType;
  final int sourceType;
  final String consumedAtRaw;
  final String? notes;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final List<DayMealLogItem> items;

  DateTime? get consumedAt => DateTime.tryParse(consumedAtRaw);

  DayMealLogEntry copyWith({
    String? id,
    String? name,
    int? mealType,
    int? sourceType,
    String? consumedAtRaw,
    String? notes,
    int? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    List<DayMealLogItem>? items,
  }) {
    return DayMealLogEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      sourceType: sourceType ?? this.sourceType,
      consumedAtRaw: consumedAtRaw ?? this.consumedAtRaw,
      notes: notes ?? this.notes,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      items: items ?? this.items,
    );
  }

  factory DayMealLogEntry.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return DayMealLogEntry(
      id: json['id'] as String? ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      mealType: (json['mealType'] as num?)?.round() ?? 0,
      sourceType: (json['sourceType'] as num?)?.round() ?? 0,
      consumedAtRaw: json['consumedAt'] as String? ?? '',
      notes: json['notes'] as String?,
      totalCalories: (json['totalCalories'] as num?)?.round() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(DayMealLogItem.fromJson)
          .toList(),
    );
  }
}
