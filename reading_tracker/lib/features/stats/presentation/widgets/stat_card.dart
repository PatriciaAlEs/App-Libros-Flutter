import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon, color: color, size: 24),
            if (icon != null) const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
