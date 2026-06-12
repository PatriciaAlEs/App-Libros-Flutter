import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';
import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';
import '../providers/books_provider.dart';
import '../widgets/completion_review_sheet.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () => const Scaffold(body: _BookDetailLoadingState()),
      error: (error, _) => const Scaffold(
        body: _BookDetailUnavailableState(
          title: 'No pudimos abrir este libro',
          message: 'Vuelve a intentarlo en unos segundos.',
        ),
      ),
      data: (books) {
        Book? book;
        for (final candidate in books) {
          if (candidate.id == bookId) {
            book = candidate;
            break;
          }
        }

        if (book == null) {
          return const Scaffold(
            body: _BookDetailUnavailableState(
              title: 'Libro no encontrado',
              message: 'Puede que haya sido eliminado o ya no esté disponible.',
            ),
          );
        }

        return _BookDetailView(book: book);
      },
    );
  }
}

class _BookDetailView extends ConsumerWidget {
  const _BookDetailView({required this.book});

  final Book book;

  Future<bool> _onStatusChanged(
    BuildContext context,
    BookStatus newStatus,
    WidgetRef ref,
  ) async {
    final completionReview = newStatus == BookStatus.completed
        ? await showModalBottomSheet<CompletionReview>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => CompletionReviewSheet(
              title: book.title,
              initialRating: book.rating,
              initialNote: book.notes,
            ),
          )
        : null;

    if (newStatus == BookStatus.completed && completionReview == null) {
      return false;
    }

    final updated = _updatedBookForStatus(newStatus, completionReview);
    await ref.read(booksProvider.notifier).updateBook(updated);
    ref.invalidate(statsProvider);
    ref.invalidate(statisticsSummaryProvider);
    ref.invalidate(readingInsightsSummaryProvider);

    if (!context.mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    return true;
  }

  Book _updatedBookForStatus(
    BookStatus newStatus,
    CompletionReview? completionReview,
  ) {
    return Book(
      id: book.id,
      title: book.title,
      author: book.author,
      totalPages: book.totalPages,
      currentPage: book.currentPage,
      rating: completionReview == null ? book.rating : completionReview.rating,
      notes: completionReview == null ? book.notes : completionReview.note,
      publisher: book.publisher,
      coverUrl: book.coverUrl,
      isbn: book.isbn,
      firstPublishYear: book.firstPublishYear,
      genre: book.genre,
      language: book.language,
      status: newStatus,
      startDate: newStatus == BookStatus.reading && book.startDate == null
          ? _today()
          : _clampDate(book.startDate),
      completedDate: newStatus == BookStatus.completed
          ? _today()
          : _clampDate(book.completedDate),
      createdAt: book.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Book _updatedBookForDates(_DatesEditResult dates) {
    final normalizedDates = _normalizeDates(
      startedAt: dates.startedAt,
      finishedAt: dates.finishedAt,
    );
    return Book(
      id: book.id,
      title: book.title,
      author: book.author,
      totalPages: book.totalPages,
      currentPage: book.currentPage,
      rating: book.rating,
      notes: book.notes,
      publisher: book.publisher,
      coverUrl: book.coverUrl,
      isbn: book.isbn,
      firstPublishYear: book.firstPublishYear,
      genre: book.genre,
      language: book.language,
      status: book.status,
      startDate: normalizedDates.startedAt,
      completedDate: normalizedDates.finishedAt,
      createdAt: book.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  ({DateTime? startedAt, DateTime? finishedAt}) _normalizeDates({
    required DateTime? startedAt,
    required DateTime? finishedAt,
  }) {
    final normalizedStartedAt = _clampDate(startedAt);
    var normalizedFinishedAt = _clampDate(finishedAt);
    if (normalizedStartedAt != null &&
        normalizedFinishedAt != null &&
        normalizedFinishedAt.isBefore(normalizedStartedAt)) {
      normalizedFinishedAt = null;
    }
    return (startedAt: normalizedStartedAt, finishedAt: normalizedFinishedAt);
  }

  DateTime? _clampDate(DateTime? date) {
    if (date == null) return null;
    final day = DateTime(date.year, date.month, date.day);
    final today = _today();
    return day.isAfter(today) ? today : day;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _onDelete(WidgetRef ref, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteDialog(),
    );

    if (confirm == true) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
      ref.invalidate(statsProvider);
      ref.invalidate(statisticsSummaryProvider);
      ref.invalidate(readingInsightsSummaryProvider);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _openPagesEditor(BuildContext context, WidgetRef ref) async {
    final pages = await showModalBottomSheet<_PagesEditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PagesEditSheet(book: book),
    );
    if (pages == null) return;

    await ref
        .read(booksProvider.notifier)
        .updateBook(
          book.copyWith(
            currentPage: pages.currentPage,
            totalPages: pages.totalPages,
            updatedAt: DateTime.now(),
          ),
        );
    ref.invalidate(statsProvider);
    ref.invalidate(statisticsSummaryProvider);
    ref.invalidate(readingInsightsSummaryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paginas actualizadas')));
  }

  Future<void> _openDatesEditor(BuildContext context, WidgetRef ref) async {
    final dates = await showDialog<_DatesEditResult>(
      context: context,
      builder: (_) => _DatesEditDialog(book: book),
    );
    if (dates == null) return;

    await ref
        .read(booksProvider.notifier)
        .updateBook(_updatedBookForDates(dates));
    ref.invalidate(statsProvider);
    ref.invalidate(statisticsSummaryProvider);
    ref.invalidate(readingInsightsSummaryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fechas actualizadas')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(readingSessionsForBookProvider(book.id));
    final sessions = sessionsAsync.valueOrNull ?? const <ReadingSession>[];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.scaffoldBackgroundColor,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
              ],
              stops: const [0, 0.34, 1],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  112,
                ),
                sliver: SliverList.list(
                  children: [
                    _DetailTopBar(
                      onBack: () => Navigator.pop(context),
                      onDelete: () => _onDelete(ref, context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _BookHero(book: book),
                    const SizedBox(height: AppSpacing.xl),
                    _PremiumProgressCard(
                      book: book,
                      onEditPages: () => _openPagesEditor(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _QuickActions(
                      hasNotes: book.notes?.isNotEmpty == true,
                      onEditDates: () => _openDatesEditor(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _StatusSection(
                      book: book,
                      onStatusChanged: (status) =>
                          _onStatusChanged(context, status, ref),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _EditorialInfoGrid(book: book),
                    const SizedBox(height: AppSpacing.xl),
                    _SynopsisSection(book: book),
                    const SizedBox(height: AppSpacing.xl),
                    _ReadingTimeline(sessions: sessions),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onBack, required this.onDelete});

  final VoidCallback onBack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _CircleAction(icon: Icons.arrow_back_rounded, onTap: onBack),
        const Spacer(),
        Text(
          'Ficha editorial',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.78),
            letterSpacing: 2.2,
          ),
        ),
        const Spacer(),
        _CircleAction(
          icon: Icons.delete_outline_rounded,
          onTap: onDelete,
          destructive: true,
        ),
      ],
    );
  }
}

class _BookDetailLoadingState extends StatelessWidget {
  const _BookDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 112),
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 470,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < 3; index++) ...[
            Container(
              height: 118,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _BookDetailUnavailableState extends StatelessWidget {
  const _BookDetailUnavailableState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              boxShadow: AppShadows.soft(theme.colorScheme.primary),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.book, color: theme.colorScheme.primary, size: 36),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = destructive
        ? theme.colorScheme.error.withValues(alpha: 0.70)
        : theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface.withValues(
        alpha: destructive ? 0.44 : 0.72,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: destructive ? 0.12 : 0.10),
            ),
          ),
          child: Icon(icon, color: color, size: destructive ? 19 : 21),
        ),
      ),
    );
  }
}

class _BookHero extends StatelessWidget {
  const _BookHero({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.34)!;
    final accent = theme.colorScheme.secondary;
    final progress = _bookProgress(book);
    final percent = (progress * 100).round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, dark],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.50)),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: Text(
                  book.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent.withValues(alpha: 0.96),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Cover(url: book.coverUrl, width: 164, height: 246, radius: 22),
            const SizedBox(height: AppSpacing.xl),
            Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
                height: 1.04,
              ),
            ),
            if (book.author?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                book.author!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: accent.withValues(alpha: 0.96),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text(
                  '$percent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _pageProgress(book),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.74,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                color: accent.withValues(alpha: 0.96),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumProgressCard extends StatelessWidget {
  const _PremiumProgressCard({required this.book, required this.onEditPages});

  final Book book;
  final VoidCallback onEditPages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _bookProgress(book);
    final percent = (progress * 100).round();
    final remaining = _remainingPagesText(book);

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROGRESO DE LECTURA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.74),
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontFamily: AppTypography.contentFontFamily,
                  fontFamilyFallback: AppTypography.contentFallback,
                  fontSize: 46,
                  fontWeight: FontWeight.w600,
                  height: 0.95,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 7),
                child: Text(
                  '%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pageProgress(book),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.86,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (remaining != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          remaining,
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.42,
              ),
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onEditPages,
            icon: const Icon(AppIcons.edit),
            label: const Text('Actualizar progreso'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.hasNotes, required this.onEditDates});

  final bool hasNotes;
  final VoidCallback onEditDates;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: AppIcons.bookmark,
            label: 'Notas',
            helper: hasNotes ? 'Guardadas' : 'Próximamente',
            enabled: false,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: AppIcons.bookmark,
            label: 'Bookmarks',
            helper: 'Próximamente',
            enabled: false,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: AppIcons.star,
            label: 'Highlights',
            helper: 'Próximamente',
            enabled: false,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: AppIcons.time,
            label: 'Fechas',
            helper: 'Editar',
            onTap: onEditDates,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.helper,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? helper;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.48);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: enabled ? 0.66 : 0.44),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 76,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 21),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
              if (helper != null) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    helper!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.72),
                      fontSize: 10,
                    ),
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

class _EditorialInfoGrid extends StatelessWidget {
  const _EditorialInfoGrid({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _InfoPill(label: 'Género', value: _clean(book.genre)),
        _InfoPill(
          label: 'Páginas',
          value: book.totalPages == null
              ? 'Por completar'
              : '${book.totalPages}',
        ),
        _InfoPill(
          label: 'Publicación',
          value: book.firstPublishYear == null
              ? 'Por completar'
              : '${book.firstPublishYear}',
        ),
        _InfoPill(
          label: 'Rating',
          value: book.rating == null ? 'Pendiente' : _stars(book.rating!),
        ),
      ],
    );
  }

  String _clean(String? value) {
    if (value == null || value.trim().isEmpty) return 'Por completar';
    return value.trim();
  }

  String _stars(double rating) {
    final filled = rating.round().clamp(0, 5).toInt();
    return [
      ...List.filled(filled, '★'),
      ...List.filled(5 - filled, '☆'),
    ].join();
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: (MediaQuery.sizeOf(context).width - 48) / 2,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SynopsisSection extends StatelessWidget {
  const _SynopsisSection({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final notes = book.notes?.trim();
    final text = notes == null || notes.isEmpty
        ? 'Aún no hay notas para este libro. Cuando registres impresiones, vivirán aquí como parte de tu diario lector.'
        : notes;
    final theme = Theme.of(context);

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sinopsis y notas',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 44,
            height: 3,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.48)),
        ],
      ),
    );
  }
}

class _ReadingTimeline extends StatelessWidget {
  const _ReadingTimeline({required this.sessions});

  final List<ReadingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final visible = [...sessions]..sort((a, b) => b.date.compareTo(a.date));
    final recent = visible.take(4).toList();
    final theme = Theme.of(context);

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sesiones recientes',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (recent.isEmpty)
            Text(
              'Las sesiones recientes aparecerán aquí cuando registres lectura.',
              style: theme.textTheme.bodyMedium,
            )
          else
            for (var index = 0; index < recent.length; index++) ...[
              _TimelineRow(session: recent[index]),
              if (index < recent.length - 1)
                Divider(
                  height: 22,
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
            ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.session});

  final ReadingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (session.pagesRead > 0) '${session.pagesRead} páginas',
      if (session.minutes > 0) '${session.minutes} min',
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.only(top: 4),
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.isEmpty ? 'Sesión registrada' : details,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _humanDate(session.date),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.72),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorialSurface extends StatelessWidget {
  const _EditorialSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: child,
    );
  }
}

class _StatusSection extends StatefulWidget {
  const _StatusSection({required this.book, required this.onStatusChanged});

  final Book book;
  final Future<bool> Function(BookStatus status) onStatusChanged;

  @override
  State<_StatusSection> createState() => _StatusSectionState();
}

class _StatusSectionState extends State<_StatusSection> {
  late BookStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.book.status;
  }

  @override
  void didUpdateWidget(covariant _StatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.status != widget.book.status) {
      _selectedStatus = widget.book.status;
    }
  }

  Future<void> _handleStatusChanged(BookStatus value) async {
    if (value == widget.book.status) return;

    setState(() => _selectedStatus = value);
    final saved = await widget.onStatusChanged(value);
    if (!saved && mounted) {
      setState(() => _selectedStatus = widget.book.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado lector',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Actualiza el lugar de este libro dentro de tu biblioteca.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<BookStatus>(
            key: ValueKey(_selectedStatus),
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface.withValues(alpha: 0.72),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
              ),
            ),
            items: BookStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _handleStatusChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PagesEditResult {
  const _PagesEditResult({this.currentPage, this.totalPages});

  final int? currentPage;
  final int? totalPages;
}

class _PagesEditSheet extends StatefulWidget {
  const _PagesEditSheet({required this.book});

  final Book book;

  @override
  State<_PagesEditSheet> createState() => _PagesEditSheetState();
}

class _PagesEditSheetState extends State<_PagesEditSheet> {
  late final TextEditingController _currentPageController;
  late final TextEditingController _totalPagesController;

  @override
  void initState() {
    super.initState();
    _currentPageController = TextEditingController(
      text: widget.book.currentPage?.toString() ?? '',
    );
    _totalPagesController = TextEditingController(
      text: widget.book.totalPages?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _currentPageController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  void _save() {
    final currentPage = int.tryParse(_currentPageController.text.trim());
    final totalPages = int.tryParse(_totalPagesController.text.trim());

    Navigator.pop(
      context,
      _PagesEditResult(
        currentPage: currentPage != null && currentPage > 0
            ? currentPage
            : null,
        totalPages: totalPages != null && totalPages > 0 ? totalPages : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Editar páginas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pagina actual',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalPagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total de páginas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: const Text('Guardar páginas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatesEditResult {
  const _DatesEditResult({this.startedAt, this.finishedAt});

  final DateTime? startedAt;
  final DateTime? finishedAt;
}

class _DatesEditDialog extends StatefulWidget {
  const _DatesEditDialog({required this.book});

  final Book book;

  @override
  State<_DatesEditDialog> createState() => _DatesEditDialogState();
}

class _DatesEditDialogState extends State<_DatesEditDialog> {
  DateTime? _startedAt;
  DateTime? _finishedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = _clampDate(widget.book.startedAt);
    _finishedAt = _clampDate(widget.book.finishedAt);
    if (_startedAt != null &&
        _finishedAt != null &&
        _finishedAt!.isBefore(_startedAt!)) {
      _finishedAt = null;
    }
  }

  Future<void> _pickStartedAt() async {
    final selected = await _pickDate(_startedAt);
    if (selected != null) {
      setState(() {
        _startedAt = selected;
        if (_finishedAt != null && _finishedAt!.isBefore(selected)) {
          _finishedAt = null;
        }
      });
    }
  }

  Future<void> _pickFinishedAt() async {
    final selected = await _pickDate(
      _finishedAt ?? _startedAt,
      firstDate: _startedAt,
    );
    if (selected != null) {
      setState(() => _finishedAt = selected);
    }
  }

  Future<DateTime?> _pickDate(DateTime? initialDate, {DateTime? firstDate}) {
    final today = _today();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final clampedInitialDate = _clampDate(initialDate ?? today)!;
    final effectiveInitialDate = clampedInitialDate.isBefore(effectiveFirstDate)
        ? effectiveFirstDate
        : clampedInitialDate;
    return showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: today,
    );
  }

  void _save() {
    final startedAt = _clampDate(_startedAt);
    var finishedAt = _clampDate(_finishedAt);
    if (startedAt != null &&
        finishedAt != null &&
        finishedAt.isBefore(startedAt)) {
      finishedAt = null;
    }
    Navigator.pop(
      context,
      _DatesEditResult(startedAt: startedAt, finishedAt: finishedAt),
    );
  }

  DateTime? _clampDate(DateTime? date) {
    if (date == null) return null;
    final day = DateTime(date.year, date.month, date.day);
    final today = _today();
    return day.isAfter(today) ? today : day;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _format(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar fechas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Anadido'),
              subtitle: Text(_format(widget.book.addedAt)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Empezado'),
              subtitle: Text(_format(_startedAt)),
              trailing: IconButton(
                tooltip: 'Quitar fecha de inicio',
                icon: const Icon(Icons.close),
                onPressed: _startedAt == null
                    ? null
                    : () => setState(() {
                        _startedAt = null;
                        _finishedAt = null;
                      }),
              ),
              onTap: _pickStartedAt,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Terminado'),
              subtitle: Text(_format(_finishedAt)),
              trailing: IconButton(
                tooltip: 'Quitar fecha de fin',
                icon: const Icon(Icons.close),
                onPressed: _finishedAt == null
                    ? null
                    : () => setState(() => _finishedAt = null),
              ),
              onTap: _pickFinishedAt,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar fechas')),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.url,
    required this.width,
    required this.height,
    required this.radius,
  });

  final String? url;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(AppIcons.book, color: theme.colorScheme.primary),
    );

    if (url == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
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

String _pageProgress(Book book) {
  if (book.currentPage == null || book.totalPages == null) {
    return 'Progreso por registrar';
  }
  return '${book.currentPage} / ${book.totalPages} p.';
}

String? _remainingPagesText(Book book) {
  final currentPage = book.currentPage;
  final totalPages = book.totalPages;
  if (currentPage == null || totalPages == null || totalPages <= 0) {
    return null;
  }
  final remaining = (totalPages - currentPage).clamp(0, totalPages);
  if (remaining == 0) return 'Lectura completa';
  return '$remaining páginas restantes';
}

String _humanDate(DateTime date) {
  final today = DateTime.now();
  final currentDay = DateTime(today.year, today.month, today.day);
  final sessionDay = DateTime(date.year, date.month, date.day);
  final difference = currentDay.difference(sessionDay).inDays;
  if (difference == 0) return 'Hoy';
  if (difference == 1) return 'Ayer';
  if (difference > 1 && difference < 7) return 'Hace $difference días';

  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar libro'),
      content: const Text('Esta accion no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
