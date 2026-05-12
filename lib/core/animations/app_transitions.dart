import 'package:flutter/material.dart';

import 'motion_tokens.dart';

abstract final class AppTransitions {
  static PageRouteBuilder<T> slideFromRight<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: MotionTokens.medium,
      reverseTransitionDuration: MotionTokens.medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: MotionTokens.enter),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: MotionTokens.enter)),
            child: child,
          ),
        );
      },
    );
  }

  static PageRouteBuilder<T> fade<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: MotionTokens.medium,
      reverseTransitionDuration: MotionTokens.medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: MotionTokens.enter),
          child: child,
        );
      },
    );
  }
}
