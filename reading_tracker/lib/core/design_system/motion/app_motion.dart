import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
}

class AppFadeSlideTransition extends StatelessWidget {
  const AppFadeSlideTransition({
    super.key,
    required this.child,
    this.offset = const Offset(0, 0.04),
    this.duration = AppMotion.normal,
    this.curve = AppMotion.standard,
  });

  final Widget child;
  final Offset offset;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
