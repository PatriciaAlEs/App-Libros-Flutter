import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';
import 'readpp_surface.dart';

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

    return ReadPpSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 0.96,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
