import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;
}

class AppRadii {
  const AppRadii._();

  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get control => BorderRadius.circular(md);
}

class AppElevations {
  const AppElevations._();

  static const double none = 0;
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> editorial(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];
}
