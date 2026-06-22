import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/data/datasources/book_api_datasource.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/entities/book_search_result.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../domain/entities/statistics_summary.dart';
import '../providers/annual_goal_cover_controller.dart';
import '../providers/statistics_summary_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);
    final annualGoalCover = ref.watch(annualGoalCoverControllerProvider);
    final books = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
    final sessionsAsync = ref.watch(
      readingSessionsForRangeProvider(_statsActivityRange()),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.10),
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
          child: summaryAsync.when(
            loading: () => const _StatsLoadingState(),
            error: (error, _) => _StatsErrorState(
              onRetry: () => ref.invalidate(statisticsSummaryProvider),
            ),
            data: (summary) {
              final effectiveAnnualGoalCover =
                  annualGoalCover ?? _latestCompletedBookCover(books);
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  128,
                ),
                children: [
                  _StatsHeader(readerProfile: readerProfile),
                  const SizedBox(height: AppSpacing.xxl),
                  if (summary.totalBooks == 0 &&
                      summary.totalPagesRead == 0) ...[
                    const _StatsEmptyState(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SectionHeader(
                    title: 'Objetivo anual',
                    actionLabel: 'Editar',
                    onAction: () => _editAnnualGoal(
                      context,
                      ref,
                      currentGoal: summary.annualReadingGoal,
                    ),
                  ),
                  _AnnualGoalSection(
                    annualReadingGoal: summary.annualReadingGoal,
                    completedThisYear: summary.completedThisYear,
                    annualGoalProgress: summary.annualGoalProgress,
                    booksRemainingForAnnualGoal:
                        summary.booksRemainingForAnnualGoal,
                    isAnnualGoalReached: summary.isAnnualGoalReached,
                    cover: effectiveAnnualGoalCover,
                    onEditGoal: () => _editAnnualGoal(
                      context,
                      ref,
                      currentGoal: summary.annualReadingGoal,
                    ),
                    onSearchCover: () => _searchAnnualGoalCover(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _StatsHero(summary: summary),
                  const SizedBox(height: AppSpacing.xl),
                  _PremiumStatsVisuals(
                    summary: summary,
                    books: books,
                    sessions: sessionsAsync.valueOrNull ?? const [],
                    isLoadingSessions: sessionsAsync.isLoading,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _StatsSection(
                    title: 'Lectura',
                    children: [
                      MetricCard(
                        icon: AppIcons.library,
                        label: 'Biblioteca',
                        value: '${summary.totalBooks}',
                        subtitle: 'libros guardados',
                      ),
                      MetricCard(
                        icon: AppIcons.bookmark,
                        label: 'Pendientes',
                        value: '${summary.toReadBooks}',
                      ),
                      MetricCard(
                        icon: AppIcons.book,
                        label: 'Leyendo',
                        value: '${summary.readingBooks}',
                      ),
                      MetricCard(
                        icon: Icons.check_circle_outline,
                        label: 'Completados',
                        value: '${summary.completedBooks}',
                      ),
                      MetricCard(
                        icon: Icons.pause_circle_outline,
                        label: 'Pausados',
                        value: '${summary.pausedBooks}',
                      ),
                      MetricCard(
                        icon: Icons.block_outlined,
                        label: 'Abandonados',
                        value: '${summary.abandonedBooks}',
                      ),
                      MetricCard(
                        icon: AppIcons.fire,
                        label: 'Racha actual',
                        value: '${summary.currentStreakDays}',
                        subtitle: 'días seguidos',
                      ),
                      MetricCard(
                        icon: AppIcons.star,
                        label: 'Valoración media',
                        value: _formatAverageRating(summary.averageRating),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _StatsSection(
                    title: 'Tiempo',
                    children: [
                      MetricCard(
                        icon: AppIcons.pages,
                        label: 'Páginas esta semana',
                        value: '${summary.pagesReadThisWeek}',
                      ),
                      MetricCard(
                        icon: AppIcons.calendar,
                        label: 'Páginas este mes',
                        value: '${summary.pagesReadThisMonth}',
                      ),
                      MetricCard(
                        icon: AppIcons.time,
                        label: 'Tiempo esta semana',
                        value: _formatMinutes(summary.minutesReadThisWeek),
                      ),
                      MetricCard(
                        icon: Icons.hourglass_bottom_outlined,
                        label: 'Tiempo este mes',
                        value: _formatMinutes(summary.minutesReadThisMonth),
                      ),
                      MetricCard(
                        icon: Icons.trending_up_outlined,
                        label: 'Promedio por día activo',
                        value:
                            '${_formatAverage(summary.averagePagesPerActiveDay)} pag.',
                        subtitle:
                            '${_formatAverage(summary.averageMinutesPerActiveDay)} min',
                      ),
                      MetricCard(
                        icon: Icons.event_available_outlined,
                        label: 'Días activos este mes',
                        value: '${summary.activeDaysThisMonth}',
                      ),
                      MetricCard(
                        icon: Icons.bolt_outlined,
                        label: 'Día más activo',
                        value: _formatMostActiveDay(summary.mostActiveDayDate),
                        subtitle: _formatMostActiveDayActivity(
                          summary.mostActiveDayPages,
                          summary.mostActiveDayMinutes,
                        ),
                      ),
                      MetricCard(
                        icon: Icons.emoji_events_outlined,
                        label: 'Mejor racha',
                        value: '${summary.bestStreakDays}',
                        subtitle: 'mejor marca',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatAverageRating(double? rating) {
    if (rating == null) return '-';
    return rating.toStringAsFixed(rating % 1 == 0 ? 1 : 2);
  }

  String _formatAverage(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}min';
  }

  String _formatMostActiveDay(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMostActiveDayActivity(int pagesRead, int minutes) {
    final parts = <String>[
      if (pagesRead > 0) '$pagesRead pag.',
      if (minutes > 0) '$minutes min',
    ];
    return parts.isEmpty ? 'Sin sesiones' : parts.join(' · ');
  }

  Future<void> _editAnnualGoal(
    BuildContext context,
    WidgetRef ref, {
    required int? currentGoal,
  }) async {
    final goal = await showDialog<int>(
      context: context,
      builder: (_) => _AnnualGoalDialog(initialGoal: currentGoal),
    );
    if (goal == null) return;

    await ref.read(saveAnnualReadingGoalProvider)(goal);
    ref.invalidate(statisticsSummaryProvider);
  }

  Future<void> _searchAnnualGoalCover(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedBook = await showDialog<BookSearchResult>(
      context: context,
      builder: (_) => const _AnnualGoalCoverSearchDialog(),
    );
    if (selectedBook == null) return;

    await ref
        .read(annualGoalCoverControllerProvider.notifier)
        .selectBook(selectedBook);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Portada del reto actualizada')),
    );
  }
}

AnnualGoalCover? _latestCompletedBookCover(List<Book> books) {
  final completedBooks = books
      .where((book) => book.status == BookStatus.completed)
      .toList();
  if (completedBooks.isEmpty) return null;

  completedBooks.sort((a, b) {
    final aDate = a.updatedAt ?? a.completedDate ?? a.createdAt;
    final bDate = b.updatedAt ?? b.completedDate ?? b.createdAt;
    return bDate.compareTo(aDate);
  });

  final book = completedBooks.first;
  return AnnualGoalCover(
    title: book.title,
    author: book.author,
    coverUrl: book.coverUrl,
    isbn: book.isbn,
  );
}

DateRange _statsActivityRange() {
  final now = DateTime.now();
  final start = DateTime(now.year - 1, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return DateRange(start: start, end: end);
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.readerProfile});

  final ReaderProfile readerProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadPpPageHeader(
          readerProfile: readerProfile,
          onTap: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          onProfileTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/settings',
            (_) => false,
          ),
          onAddBookTap: () => Navigator.pushNamed(context, '/book/add'),
          onCalendarTap: () => Navigator.pushNamed(context, '/calendar'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Una lectura clara de tu biblioteca, tus ritmos y tu reto anual.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.30)!;
    final accent = theme.colorScheme.secondary;
    final year = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, dark],
        ),
        borderRadius: BorderRadius.circular(32),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PULSO LECTOR',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent.withValues(alpha: 0.96),
              letterSpacing: 2.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  value: '${summary.completedThisYear}',
                  label: 'libros $year',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  value: '${summary.currentStreakDays}',
                  label: 'racha',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  value: _compactNumber(summary.totalPagesRead),
                  label: 'páginas',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(AppIcons.chart, color: accent, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${summary.completedBooks} completados · ${summary.readingBooks} en curso · ${summary.toReadBooks} pendientes',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 0.92,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.74),
          ),
        ),
      ],
    );
  }
}

class _AnnualGoalSection extends StatelessWidget {
  const _AnnualGoalSection({
    required this.annualReadingGoal,
    required this.completedThisYear,
    required this.annualGoalProgress,
    required this.booksRemainingForAnnualGoal,
    required this.isAnnualGoalReached,
    required this.cover,
    required this.onEditGoal,
    required this.onSearchCover,
  });

  final int? annualReadingGoal;
  final int completedThisYear;
  final double? annualGoalProgress;
  final int? booksRemainingForAnnualGoal;
  final bool isAnnualGoalReached;
  final AnnualGoalCover? cover;
  final VoidCallback onEditGoal;
  final VoidCallback onSearchCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoal = annualReadingGoal != null;
    final rawProgress = annualGoalProgress ?? 0;
    final progress = (rawProgress / 100).clamp(0.0, 1.0).toDouble();
    final percent = rawProgress.clamp(0, 100).round();

    if (!hasGoal) {
      return ReadPpEmptyState(
        icon: AppIcons.chart,
        title: 'Configura tu reto lector',
        description:
            'Define cuántos libros quieres leer este año y ReadPp te mostrará el avance del reto con claridad.',
        actionLabel: 'Configurar reto',
        onAction: onEditGoal,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnnualGoalCoverFrame(cover: cover),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasGoal
                          ? '$completedThisYear / $annualReadingGoal libros'
                          : 'Define tu reto lector',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      cover?.title ?? 'Elige un libro para tu reto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (cover?.author?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        cover!.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _GoalProgressRing(
                progress: hasGoal ? progress : 0,
                label: hasGoal ? '$percent%' : '-',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onEditGoal,
                icon: Icon(hasGoal ? AppIcons.edit : AppIcons.add, size: 18),
                label: Text(hasGoal ? 'Editar objetivo' : 'Definir objetivo'),
              ),
              OutlinedButton.icon(
                onPressed: onSearchCover,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(cover == null ? 'Buscar libro' : 'Cambiar libro'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: hasGoal ? progress : 0,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.26,
              ),
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _GoalMetric(label: 'Avance', value: hasGoal ? '$percent%' : '-'),
              _GoalMetric(label: 'Completados', value: '$completedThisYear'),
              _GoalMetric(
                label: hasGoal
                    ? isAnnualGoalReached
                          ? 'Meta'
                          : 'Restan'
                    : 'Objetivo',
                value: hasGoal
                    ? isAnnualGoalReached
                          ? 'Alcanzada'
                          : '${booksRemainingForAnnualGoal ?? 0}'
                    : 'Sin definir',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    if (annualReadingGoal == null) {
      return 'Elige cuántos libros quieres leer este año.';
    }
    if (isAnnualGoalReached) {
      return 'Objetivo alcanzado. Buen ritmo.';
    }
    return 'Vas por $completedThisYear de $annualReadingGoal libros.';
  }
}

class _GoalProgressRing extends StatelessWidget {
  const _GoalProgressRing({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Progreso del reto lector',
      value: label,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 82,
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0, 1).toDouble()),
                duration: AppMotion.slow,
                curve: AppMotion.standard,
                builder: (context, value, child) {
                  return CustomPaint(
                    size: const Size.square(82),
                    painter: _RingPainter(
                      progress: value,
                      trackColor: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.28,
                      ),
                      progressColor: theme.colorScheme.secondary,
                    ),
                  );
                },
              ),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.11;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -1.5708, 6.2832, false, trackPaint);
    canvas.drawArc(
      rect,
      -1.5708,
      6.2832 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        trackColor != oldDelegate.trackColor ||
        progressColor != oldDelegate.progressColor;
  }
}

class _AnnualGoalCoverFrame extends StatelessWidget {
  const _AnnualGoalCoverFrame({required this.cover});

  final AnnualGoalCover? cover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = cover?.coverUrl;

    return Container(
      width: 72,
      height: 104,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl == null || coverUrl.isEmpty
          ? Icon(
              AppIcons.book,
              color: theme.colorScheme.primary.withValues(alpha: 0.62),
              size: 28,
            )
          : Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                AppIcons.book,
                color: theme.colorScheme.primary.withValues(alpha: 0.62),
                size: 28,
              ),
            ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 132,
      height: 92,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _compactNumber(int value) {
  if (value < 1000) return '$value';
  final compact = value / 1000;
  final decimals = compact >= 10 || compact % 1 == 0 ? 0 : 1;
  return '${compact.toStringAsFixed(decimals)}k';
}

class _AnnualGoalDialog extends StatefulWidget {
  const _AnnualGoalDialog({required this.initialGoal});

  final int? initialGoal;

  @override
  State<_AnnualGoalDialog> createState() => _AnnualGoalDialogState();
}

class _AnnualGoalDialogState extends State<_AnnualGoalDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialGoal?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final goal = int.tryParse(_controller.text.trim());
    if (goal == null || goal <= 0) {
      setState(() => _error = 'Introduce un número mayor que 0.');
      return;
    }

    Navigator.pop(context, goal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Objetivo anual'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Libros para este año',
          hintText: 'Ej. 12',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

class _AnnualGoalCoverSearchDialog extends ConsumerStatefulWidget {
  const _AnnualGoalCoverSearchDialog();

  @override
  ConsumerState<_AnnualGoalCoverSearchDialog> createState() =>
      _AnnualGoalCoverSearchDialogState();
}

class _AnnualGoalCoverSearchDialogState
    extends ConsumerState<_AnnualGoalCoverSearchDialog> {
  final _controller = TextEditingController();
  Future<List<BookSearchResult>>? _searchFuture;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _query = query;
      _searchFuture = ref.read(bookApiDatasourceProvider).searchBooks(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar libro'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('annual_goal_cover_search_field'),
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Título, autor o ISBN',
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _search,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: AppSpacing.md),
            _SearchResults(future: _searchFuture, query: _query),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.future, required this.query});

  final Future<List<BookSearchResult>>? future;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const _CoverSearchEmptyState();
    }

    return FutureBuilder<List<BookSearchResult>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppSearchSkeletonList(itemCount: 2);
        }

        if (snapshot.hasError) {
          return _CoverSearchMessage(
            icon: Icons.wifi_off_rounded,
            title: 'No pudimos buscar',
            message: _coverSearchErrorMessage(snapshot.error),
          );
        }

        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return _CoverSearchMessage(
            icon: Icons.search_off_rounded,
            title: 'Sin resultados',
            message: 'No encontramos resultados para esa búsqueda.',
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final book = results[index];
              return _CoverSearchResultTile(book: book);
            },
          ),
        );
      },
    );
  }
}

String _coverSearchErrorMessage(Object? error) {
  if (error is BookSearchException) {
    return switch (error.kind) {
      BookSearchFailureKind.connection => 'Parece que no hay conexión.',
      BookSearchFailureKind.timeout =>
        'La búsqueda está tardando más de lo normal. Reintenta.',
      BookSearchFailureKind.invalidResponse =>
        'Open Library devolvió una respuesta inesperada. Puedes reintentar.',
      BookSearchFailureKind.api =>
        'Open Library no respondió. Puedes reintentar o añadirlo manualmente.',
    };
  }

  return 'Open Library no respondió. Puedes reintentar o añadirlo manualmente.';
}

class _CoverSearchEmptyState extends StatelessWidget {
  const _CoverSearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _CoverSearchMessage(
      icon: Icons.search_rounded,
      title: 'Busca un libro',
      message: 'Puedes usar título, autora o ISBN.',
    );
  }
}

class _CoverSearchMessage extends StatelessWidget {
  const _CoverSearchMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverSearchResultTile extends StatelessWidget {
  const _CoverSearchResultTile({required this.book});

  final BookSearchResult book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context, book),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _SearchCoverThumb(url: book.coverUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resultSubtitle(book),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resultSubtitle(BookSearchResult book) {
    final parts = <String>[
      if (book.author?.isNotEmpty == true) book.author!,
      if (book.firstPublishYear != null) '${book.firstPublishYear}',
      if (book.coverUrl == null) 'Sin portada',
    ];
    return parts.isEmpty ? 'Resultado de Open Library' : parts.join(' · ');
  }
}

class _SearchCoverThumb extends StatelessWidget {
  const _SearchCoverThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: 42,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        AppIcons.book,
        color: theme.colorScheme.primary.withValues(alpha: 0.62),
        size: 18,
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 42,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _PremiumStatsVisuals extends StatelessWidget {
  const _PremiumStatsVisuals({
    required this.summary,
    required this.books,
    required this.sessions,
    required this.isLoadingSessions,
  });

  final StatisticsSummary summary;
  final List<Book> books;
  final List<ReadingSession> sessions;
  final bool isLoadingSessions;

  @override
  Widget build(BuildContext context) {
    final statusSegments = _statusSegments(context, summary);
    final genreSegments = _genreSegments(context, books);
    final weeklyMinutes = _weeklyMinutes(sessions);
    final monthlyPages = _monthlyPages(sessions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mapa lector'),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 720;
            final width = twoColumns
                ? (constraints.maxWidth - AppSpacing.md) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: width,
                  child: _DonutDistributionCard(
                    title: 'Estado de biblioteca',
                    subtitle: '${summary.totalBooks} libros registrados',
                    segments: statusSegments,
                    emptyMessage: 'Añade libros para ver tu mapa lector.',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _DonutDistributionCard(
                    title: 'Géneros',
                    subtitle: 'Distribución por libros con género',
                    segments: genreSegments,
                    emptyMessage: 'Aún no hay géneros suficientes.',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ActivityBarCard(
                    title: 'Tiempo reciente',
                    subtitle: isLoadingSessions
                        ? 'Cargando sesiones...'
                        : 'Minutos por semana',
                    bars: weeklyMinutes,
                    unit: 'min',
                    emptyMessage:
                        'Registra sesiones para ver tu ritmo semanal.',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ActivityBarCard(
                    title: 'Páginas por mes',
                    subtitle: monthlyPages.last.value <= 0
                        ? 'Últimos meses'
                        : '${monthlyPages.last.value} pág. este mes',
                    bars: monthlyPages,
                    unit: 'pág.',
                    emptyMessage:
                        'Cuando registres páginas, aparecerá tu curva mensual.',
                  ),
                ),
                SizedBox(width: width, child: const _FormatDistributionCard()),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DonutDistributionCard extends StatelessWidget {
  const _DonutDistributionCard({
    required this.title,
    required this.subtitle,
    required this.segments,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final List<_ChartSegment> segments;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);

    return _PremiumChartCard(
      title: title,
      subtitle: subtitle,
      child: total == 0
          ? _ChartEmptyMessage(message: emptyMessage)
          : Semantics(
              label: _chartSegmentsSemanticLabel(title, total, segments),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    SizedBox(
                      width: 132,
                      height: 132,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: AppMotion.slow,
                        curve: AppMotion.standard,
                        builder: (context, value, child) {
                          return CustomPaint(
                            painter: _DonutPainter(
                              segments: segments,
                              animationValue: value,
                            ),
                            child: Center(
                              child: Text(
                                '$total',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: _ChartLegend(segments: segments)),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ActivityBarCard extends StatelessWidget {
  const _ActivityBarCard({
    required this.title,
    required this.subtitle,
    required this.bars,
    required this.unit,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final List<_ChartPoint> bars;
  final String unit;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final total = bars.fold<int>(0, (sum, point) => sum + point.value);

    return _PremiumChartCard(
      title: title,
      subtitle: subtitle,
      child: total == 0
          ? _ChartEmptyMessage(message: emptyMessage)
          : Semantics(
              label: _chartPointsSemanticLabel(title, bars, unit),
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 178,
                  child: _BarChart(points: bars, unit: unit),
                ),
              ),
            ),
    );
  }
}

class _FormatDistributionCard extends StatelessWidget {
  const _FormatDistributionCard();

  @override
  Widget build(BuildContext context) {
    return const _PremiumChartCard(
      title: 'Formatos',
      subtitle: 'Metadata pendiente',
      child: _ChartEmptyMessage(
        message:
            'ReadPp todavía no guarda formato de lectura. La visualización queda preparada.',
      ),
    );
  }
}

class _PremiumChartCard extends StatelessWidget {
  const _PremiumChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.segments});

  final List<_ChartSegment> segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final segment in segments.where((segment) => segment.value > 0))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    segment.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  total == 0
                      ? '${segment.value}'
                      : '${((segment.value / total) * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartEmptyMessage extends StatelessWidget {
  const _ChartEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.points, required this.unit});

  final List<_ChartPoint> points;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = points.fold<int>(
      1,
      (max, point) => point.value > max ? point.value : max,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final point in points)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (point.value / maxValue).clamp(0.04, 1.0),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: AppMotion.slow,
                          curve: AppMotion.standard,
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              heightFactor: value,
                              alignment: Alignment.bottomCenter,
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: point.color,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(999),
                                bottom: Radius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    point.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    point.value <= 0 ? '-' : '${point.value} $unit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments, required this.animationValue});

  final List<_ChartSegment> segments;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    if (total <= 0) return;

    final stroke = size.shortestSide * 0.16;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    var start = -math.pi / 2;
    for (final segment in segments.where((segment) => segment.value > 0)) {
      final sweep = (segment.value / total) * math.pi * 2 * animationValue;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return segments != oldDelegate.segments ||
        animationValue != oldDelegate.animationValue;
  }
}

class _ChartSegment {
  const _ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

String _chartSegmentsSemanticLabel(
  String title,
  int total,
  List<_ChartSegment> segments,
) {
  final values = segments
      .where((segment) => segment.value > 0)
      .map((segment) => '${segment.label}: ${segment.value}')
      .join(', ');
  return '$title. Total: $total. $values.';
}

String _chartPointsSemanticLabel(
  String title,
  List<_ChartPoint> points,
  String unit,
) {
  final values = points
      .map((point) => '${point.label}: ${point.value} $unit')
      .join(', ');
  return '$title. $values.';
}

List<_ChartSegment> _statusSegments(
  BuildContext context,
  StatisticsSummary summary,
) {
  final scheme = Theme.of(context).colorScheme;
  final primary = scheme.primary;
  final secondary = scheme.secondary;
  final dark = Color.lerp(primary, Colors.black, 0.30)!;

  return [
    _ChartSegment(
      label: 'Pendientes',
      value: summary.toReadBooks,
      color: scheme.primaryContainer.withValues(alpha: 0.82),
    ),
    _ChartSegment(
      label: 'Leyendo',
      value: summary.readingBooks,
      color: secondary,
    ),
    _ChartSegment(
      label: 'Completados',
      value: summary.completedBooks,
      color: primary,
    ),
    _ChartSegment(
      label: 'Abandonados',
      value: summary.abandonedBooks,
      color: dark,
    ),
  ];
}

List<_ChartSegment> _genreSegments(BuildContext context, List<Book> books) {
  final scheme = Theme.of(context).colorScheme;
  final counts = <String, int>{};
  for (final book in books) {
    final genre = book.genre?.trim();
    if (genre == null || genre.isEmpty) continue;
    counts[genre] = (counts[genre] ?? 0) + 1;
  }

  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final palette = [
    scheme.primary,
    scheme.secondary,
    Color.lerp(scheme.primary, Colors.black, 0.24)!,
    Color.lerp(scheme.secondary, Colors.white, 0.22)!,
    scheme.tertiary,
  ];

  final visible = entries.take(4).toList();
  final remaining = entries
      .skip(4)
      .fold<int>(0, (sum, item) => sum + item.value);

  return [
    for (var index = 0; index < visible.length; index++)
      _ChartSegment(
        label: visible[index].key,
        value: visible[index].value,
        color: palette[index % palette.length],
      ),
    if (remaining > 0)
      _ChartSegment(label: 'Otros', value: remaining, color: scheme.outline),
  ];
}

List<_ChartPoint> _weeklyMinutes(List<ReadingSession> sessions) {
  final now = DateTime.now();
  final startOfThisWeek = _startOfWeek(now);
  final points = <_ChartPoint>[];
  final colors = _chartPointColors();

  for (var offset = 5; offset >= 0; offset--) {
    final start = startOfThisWeek.subtract(Duration(days: offset * 7));
    final end = start.add(const Duration(days: 6));
    final value = sessions
        .where((session) {
          final day = _dateOnly(session.date);
          return !day.isBefore(start) && !day.isAfter(end);
        })
        .fold<int>(0, (sum, session) => sum + session.minutes);
    points.add(
      _ChartPoint(
        label: offset == 0 ? 'Ahora' : '${start.day}/${start.month}',
        value: value,
        color: colors[(5 - offset) % colors.length],
      ),
    );
  }

  return points;
}

List<_ChartPoint> _monthlyPages(List<ReadingSession> sessions) {
  return _monthlySessionPoints(
    sessions,
    valueForSession: (session) => session.pagesRead,
  );
}

List<_ChartPoint> _monthlySessionPoints(
  List<ReadingSession> sessions, {
  required int Function(ReadingSession session) valueForSession,
}) {
  final now = DateTime.now();
  final colors = _chartPointColors();
  final points = <_ChartPoint>[];

  for (var offset = 5; offset >= 0; offset--) {
    final month = DateTime(now.year, now.month - offset);
    final value = sessions
        .where((session) {
          final date = session.date;
          return date.year == month.year && date.month == month.month;
        })
        .fold<int>(0, (sum, session) => sum + valueForSession(session));
    points.add(
      _ChartPoint(
        label: _shortMonth(month),
        value: value,
        color: colors[(5 - offset) % colors.length],
      ),
    );
  }

  return points;
}

List<Color> _chartPointColors() {
  return const [
    Color(0xFFB98292),
    Color(0xFF9F6477),
    Color(0xFF84445B),
    Color(0xFF6E1F35),
    Color(0xFF5A182B),
    Color(0xFF3F6B43),
  ];
}

DateTime _startOfWeek(DateTime date) {
  final day = _dateOnly(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _shortMonth(DateTime date) {
  const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return months[date.month - 1];
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        _StatsCardGrid(children: children),
      ],
    );
  }
}

class _StatsCardGrid extends StatelessWidget {
  const _StatsCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth;
        if (constraints.maxWidth >= 640) {
          cardWidth = (constraints.maxWidth - 24) / 3;
        } else if (constraints.maxWidth >= 360) {
          cardWidth = (constraints.maxWidth - 12) / 2;
        } else {
          cardWidth = constraints.maxWidth;
        }

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, height: 150, child: child),
          ],
        );
      },
    );
  }
}

// ignore: unused_element
class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
            boxShadow: AppShadows.editorial(theme.colorScheme.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StateIcon(icon: AppIcons.chart),
              const SizedBox(height: 16),
              Text(
                'Tus estadísticas están por estrenarse',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Añade tu primer libro y registra lectura para ver ritmo, rachas y progreso.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/session/add'),
                icon: const Icon(AppIcons.add),
                label: const Text('Registrar primera sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsErrorState extends StatelessWidget {
  const _StatsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.12),
            ),
            boxShadow: AppShadows.editorial(theme.colorScheme.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StateIcon(icon: Icons.error_outline, isError: true),
              const SizedBox(height: 16),
              Text(
                'No pudimos preparar tus estadísticas',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Revisa la conexión de datos local e inténtalo otra vez.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsLoadingState extends StatelessWidget {
  const _StatsLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var index = 0; index < 5; index++) ...[
          Container(
            height: index == 0 ? 132 : 92,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon, this.isError = false});

  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 34, color: color),
    );
  }
}
