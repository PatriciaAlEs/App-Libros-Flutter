import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/book.dart';

class CurrentReadingCard extends StatelessWidget {
  const CurrentReadingCard({
    super.key,
    required this.book,
    required this.onTap,
    this.currentIndex,
    this.totalReadings,
    this.onChangeCurrentReading,
    this.isPrimaryReading = true,
  });

  final Book book;
  final VoidCallback onTap;
  final int? currentIndex;
  final int? totalReadings;
  final VoidCallback? onChangeCurrentReading;
  final bool isPrimaryReading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.34)!;
    final accent = colorScheme.secondary;
    final onDark = colorScheme.onPrimary;
    final progress = _bookProgress(book);
    final progressPercent = (progress * 100).round();
    final showPosition = currentIndex != null && totalReadings != null;
    final showChange =
        onChangeCurrentReading != null && (totalReadings ?? 0) > 1;

    return Semantics(
      button: true,
      label: isPrimaryReading
          ? 'Lectura principal: ${book.title}'
          : 'Lectura en curso: ${book.title}',
      hint: 'Abre el progreso de lectura',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(primary, Colors.white, 0.03)!, primary, dark],
            stops: const [0, 0.46, 1],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: dark.withValues(alpha: 0.28),
              blurRadius: 44,
              offset: const Offset(0, 24),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  final coverWidth = isCompact ? 106.0 : 138.0;
                  final coverHeight = isCompact ? 156.0 : 204.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardHeader(
                        isPrimaryReading: isPrimaryReading,
                        showPosition: showPosition,
                        currentIndex: currentIndex,
                        totalReadings: totalReadings,
                        showChange: showChange,
                        onChangeCurrentReading: onChangeCurrentReading,
                        accent: accent,
                        onDark: onDark,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, contentConstraints) {
                            final fittedCoverHeight =
                                contentConstraints.maxHeight;
                            final fittedCoverWidth =
                                (fittedCoverHeight * (coverWidth / coverHeight))
                                    .clamp(72.0, coverWidth)
                                    .toDouble();

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _CardBookCover(
                                  url: book.coverUrl,
                                  width: fittedCoverWidth,
                                  height: fittedCoverHeight,
                                ),
                                SizedBox(
                                  width: isCompact
                                      ? AppSpacing.lg
                                      : AppSpacing.xxl,
                                ),
                                Expanded(
                                  child: _BookIdentity(
                                    book: book,
                                    isCompact: isCompact,
                                    onDark: onDark,
                                    accent: accent,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ProgressFooter(
                        progress: progress,
                        percent: progressPercent,
                        pageText: _pageProgressText(book),
                        remainingText: _remainingPagesText(book),
                        accent: accent,
                        onDark: onDark,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.isPrimaryReading,
    required this.showPosition,
    required this.currentIndex,
    required this.totalReadings,
    required this.showChange,
    required this.onChangeCurrentReading,
    required this.accent,
    required this.onDark,
  });

  final bool isPrimaryReading;
  final bool showPosition;
  final int? currentIndex;
  final int? totalReadings;
  final bool showChange;
  final VoidCallback? onChangeCurrentReading;
  final Color accent;
  final Color onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: accent.withValues(alpha: 0.24))),
        const SizedBox(width: AppSpacing.md),
        Text(
          isPrimaryReading ? 'LECTURA PRINCIPAL' : 'LECTURA EN CURSO',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: accent.withValues(alpha: 0.95),
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Divider(color: accent.withValues(alpha: 0.24))),
        if (showPosition) ...[
          const SizedBox(width: AppSpacing.md),
          _PositionBadge(
            currentIndex: currentIndex!,
            totalReadings: totalReadings!,
            onDark: onDark,
          ),
        ],
        if (showChange) ...[
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            onPressed: onChangeCurrentReading,
            tooltip: 'Cambiar lectura principal',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: Icon(
              Icons.swap_horiz_rounded,
              color: onDark.withValues(alpha: 0.90),
              size: 20,
            ),
          ),
        ],
      ],
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({
    required this.currentIndex,
    required this.totalReadings,
    required this.onDark,
  });

  final int currentIndex;
  final int totalReadings;
  final Color onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$currentIndex / $totalReadings',
        key: const Key('current_reading_position_indicator'),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: onDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BookIdentity extends StatelessWidget {
  const _BookIdentity({
    required this.book,
    required this.isCompact,
    required this.onDark,
    required this.accent,
  });

  final Book book;
  final bool isCompact;
  final Color onDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: onDark,
            fontSize: isCompact ? 26 : 34,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        if (book.author?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            book.author!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: accent.withValues(alpha: 0.95),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressFooter extends StatelessWidget {
  const _ProgressFooter({
    required this.progress,
    required this.percent,
    required this.pageText,
    required this.remainingText,
    required this.accent,
    required this.onDark,
  });

  final double progress;
  final int percent;
  final String pageText;
  final String? remainingText;
  final Color accent;
  final Color onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: onDark.withValues(alpha: 0.76),
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$percent%',
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: onDark,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                pageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: metadataStyle,
              ),
            ),
            if (remainingText != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text(
                  '\u00b7',
                  style: metadataStyle?.copyWith(
                    color: onDark.withValues(alpha: 0.42),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  remainingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: metadataStyle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.13),
            color: accent.withValues(alpha: 1),
          ),
        ),
      ],
    );
  }
}

class _CardBookCover extends StatelessWidget {
  const _CardBookCover({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Icon(
        AppIcons.book,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.78),
        size: 32,
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;
    final uri = Uri.tryParse(url!);
    if (uri != null && uri.scheme == 'file') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File.fromUri(uri),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

double _bookProgress(Book book) {
  final currentPage = book.currentPage;
  final totalPages = book.totalPages;
  if (currentPage == null || totalPages == null || totalPages <= 0) {
    return 0;
  }
  return (currentPage / totalPages).clamp(0, 1).toDouble();
}

String _pageProgressText(Book book) {
  if (book.currentPage == null || book.totalPages == null) {
    return 'Progreso por registrar';
  }
  return '${book.currentPage} / ${book.totalPages} pág.';
}

String? _remainingPagesText(Book book) {
  final currentPage = book.currentPage;
  final totalPages = book.totalPages;
  if (currentPage == null || totalPages == null || totalPages <= 0) return null;
  final remaining = (totalPages - currentPage).clamp(0, totalPages);
  return '$remaining restantes';
}
