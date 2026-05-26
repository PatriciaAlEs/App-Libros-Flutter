import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.subtitle,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: theme.textTheme.labelLarge),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
