import 'package:flutter/material.dart';

abstract final class MotionTokens {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve standard = Curves.easeOut;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve inOut = Curves.easeInOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}
