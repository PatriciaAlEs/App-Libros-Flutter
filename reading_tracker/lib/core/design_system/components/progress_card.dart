import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../../theme/app_theme_tokens.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String value;
  final double progress;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();

    return AppFadeSlideTransition(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(value, style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(value: normalizedProgress),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
