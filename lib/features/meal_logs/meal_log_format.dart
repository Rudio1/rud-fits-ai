import 'package:rud_fits_ai/models/day_meal_log.dart';

abstract final class MealLogFormat {
  static String consumedTime(DateTime? dt) {
    if (dt == null) return '—';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String itemQuantity(DayMealLogItem item) {
    if (item.unitType == 1) {
      return '${item.quantity} g';
    }
    return '${item.quantity} u.';
  }
}
