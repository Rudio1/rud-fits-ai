import 'package:flutter/material.dart';

abstract final class CalendarToday {
  static DateTime dateOnlyLocal([DateTime? instant]) {
    final t = instant ?? DateTime.now();
    final local = t.isUtc ? t.toLocal() : t;
    return DateUtils.dateOnly(local);
  }
}
