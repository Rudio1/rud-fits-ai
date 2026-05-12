import 'package:flutter/services.dart';

abstract final class AppHaptics {
  static Future<void> success() => HapticFeedback.lightImpact();
  static Future<void> warning() => HapticFeedback.mediumImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> error() => HapticFeedback.vibrate();
}
