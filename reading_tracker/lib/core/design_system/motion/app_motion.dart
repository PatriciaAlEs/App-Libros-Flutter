import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration route = Duration(milliseconds: 260);
  static const Duration celebration = Duration(milliseconds: 1200);

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

class AppFadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  AppFadeThroughPageRoute({
    required WidgetBuilder builder,
    super.settings,
    this.slideOffset = const Offset(0.018, 0),
  }) : super(
         transitionDuration: AppMotion.route,
         reverseTransitionDuration: AppMotion.normal,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curved = CurvedAnimation(
             parent: animation,
             curve: AppMotion.standard,
             reverseCurve: Curves.easeInCubic,
           );
           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: slideOffset,
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );

  final Offset slideOffset;
}

class AppAnimatedPageSwitch extends StatelessWidget {
  const AppAnimatedPageSwitch({
    super.key,
    required this.child,
    this.duration = AppMotion.normal,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.standard,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.025, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: child,
    );
  }
}
