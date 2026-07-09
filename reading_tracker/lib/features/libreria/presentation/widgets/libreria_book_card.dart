import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class LibreriaBookCard extends StatelessWidget {
  const LibreriaBookCard({
    super.key,
    required this.title,
    required this.author,
    required this.status,
    this.coverUrl,
    this.progress,
    this.onTap,
  });

  final String title;
  final String author;
  final String status;
  final String? coverUrl;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeProgress = progress?.clamp(0.0, 1.0);

    return Semantics(
      button: onTap != null,
      label: '$title, de $author. Estado: $status.',
      child: Material(
        color: Colors.transparent,
        child: AppPressable(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: ReadPpSurface(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LibreriaCover(url: coverUrl),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        status,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (safeProgress != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        LinearProgressIndicator(
                          value: safeProgress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibreriaCover extends StatelessWidget {
  const _LibreriaCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Icon(AppIcons.book, color: theme.colorScheme.primary),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        height: 82,
        child: url == null || url!.isEmpty
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}
