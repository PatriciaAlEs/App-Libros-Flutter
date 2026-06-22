import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/motion/app_motion.dart';
import 'app_theme_tokens.dart';
import 'app_typography.dart';

enum ReadingTrackerTheme {
  burgundy(
    id: 'burgundy',
    label: 'Burgundy',
    primary: Color(0xFF6E1F35),
    primaryDark: Color(0xFF4A1324),
    accent: Color(0xFFC97C8D),
    background: Color(0xFFF8F5F2),
    surface: Color(0xFFFFFFFF),
  ),
  forest(
    id: 'forest',
    label: 'Forest',
    primary: Color(0xFF3F6B43),
    primaryDark: Color(0xFF2D4E31),
    accent: Color(0xFF89A67D),
    background: Color(0xFFF7F6F2),
    surface: Color(0xFFFFFFFF),
  );

  const ReadingTrackerTheme({
    required this.id,
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.background,
    required this.surface,
  });

  final String id;
  final String label;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color background;
  final Color surface;

  static ReadingTrackerTheme fromId(String? id) {
    return ReadingTrackerTheme.values.firstWhere(
      (theme) => theme.id == id,
      orElse: () => ReadingTrackerTheme.burgundy,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light([
    ReadingTrackerTheme theme = ReadingTrackerTheme.burgundy,
  ]) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: theme.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: theme.primary,
          onPrimary: Colors.white,
          primaryContainer: theme.accent.withValues(alpha: 0.22),
          onPrimaryContainer: theme.primaryDark,
          secondary: theme.accent,
          onSecondary: theme.primaryDark,
          secondaryContainer: theme.accent.withValues(alpha: 0.18),
          onSecondaryContainer: theme.primaryDark,
          tertiary: theme.primaryDark,
          surface: theme.surface,
          onSurface: const Color(0xFF241B1D),
          onSurfaceVariant: const Color(0xFF665C5E),
          surfaceContainerHighest: theme.background,
          outline: theme.primaryDark.withValues(alpha: 0.34),
          outlineVariant: theme.primary.withValues(alpha: 0.16),
        );

    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.roboto().fontFamily,
      fontFamilyFallback: AppTypography.contentFallback,
      scaffoldBackgroundColor: theme.background,
      textTheme: textTheme,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: theme.background,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: AppElevations.none,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: theme.surface,
        elevation: AppElevations.md,
        margin: EdgeInsets.zero,
        shadowColor: theme.primaryDark.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: theme.surface,
        indicatorColor: theme.accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (_) => textTheme.labelSmall,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.38),
          disabledForegroundColor: colorScheme.onPrimary.withValues(
            alpha: 0.76,
          ),
          animationDuration: AppMotion.fast,
          elevation: AppElevations.sm,
          shadowColor: theme.primaryDark.withValues(alpha: 0.18),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface.withValues(alpha: 0.88),
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.primary.withValues(alpha: 0.42),
          animationDuration: AppMotion.fast,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.22)),
          shadowColor: theme.primaryDark.withValues(alpha: 0.08),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.primary.withValues(alpha: 0.42),
          animationDuration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(borderRadius: AppRadii.control),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: AppElevations.lg,
        focusElevation: AppElevations.lg,
        hoverElevation: AppElevations.lg,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    return TextTheme(
      displaySmall: GoogleFonts.cormorantGaramond(
        color: colorScheme.onSurface,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.14,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        color: colorScheme.onSurface,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleLarge: GoogleFonts.roboto(
        color: colorScheme.onSurface,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleMedium: GoogleFonts.roboto(
        color: colorScheme.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.28,
      ),
      bodyMedium: GoogleFonts.roboto(
        color: colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.42,
      ),
      bodySmall: GoogleFonts.roboto(
        color: colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.34,
      ),
      labelLarge: GoogleFonts.roboto(
        color: colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      labelSmall: GoogleFonts.roboto(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }
}
