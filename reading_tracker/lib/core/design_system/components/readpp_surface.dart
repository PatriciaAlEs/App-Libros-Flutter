import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';

class ReadPpSurface extends StatelessWidget {
  const ReadPpSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = 24,
    this.opacity = 0.94,
    this.useEditorialShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;
  final bool useEditorialShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: useEditorialShadow
            ? AppShadows.editorial(theme.colorScheme.primary)
            : AppShadows.soft(theme.colorScheme.primary),
      ),
      child: child,
    );
  }
}
