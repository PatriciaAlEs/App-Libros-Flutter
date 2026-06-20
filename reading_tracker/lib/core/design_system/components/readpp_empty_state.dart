import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../../theme/app_theme_tokens.dart';
import 'readpp_surface.dart';

class ReadPpEmptyState extends StatelessWidget {
  const ReadPpEmptyState({
    super.key,
    this.icon,
    this.asset,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData? icon;
  final Widget? asset;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppFadeSlideTransition(
      offset: const Offset(0, 0.025),
      child: ReadPpSurface(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
        borderRadius: 28,
        opacity: 0.92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EmptyStateVisual(icon: icon, asset: asset),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyStateVisual extends StatelessWidget {
  const _EmptyStateVisual({required this.icon, required this.asset});

  final IconData? icon;
  final Widget? asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.secondary.withValues(alpha: 0.24),
        ),
        child:
            asset ??
            Icon(
              icon ?? Icons.auto_stories_rounded,
              size: 36,
              color: theme.colorScheme.primary,
            ),
      ),
    );
  }
}
