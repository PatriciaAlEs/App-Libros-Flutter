import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/domain/usecases/register_reading_session.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../../reading_sessions/presentation/providers/register_reading_session_provider.dart';
import '../../../reading_sessions/presentation/utils/session_completion_flow.dart';
import '../../../stats/domain/entities/statistics_summary.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final booksAsync = ref.watch(booksProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);
    final now = DateTime.now();
    final recentActivityRange = DateRange(
      start: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 30)),
      end: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
    );
    final recentSessionsAsync = ref.watch(
      readingSessionsForRangeProvider(recentActivityRange),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBook(context),
        icon: const Icon(AppIcons.add),
        label: const Text('Anadir libro'),
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary,
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.24, 0.24, 1],
            ),
          ),
          child: booksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                const Center(child: Text('No se pudo cargar el inicio.')),
            data: (books) {
              final summary =
                  summaryAsync.valueOrNull ?? const StatisticsSummary.empty();
              final recentSessions =
                  recentSessionsAsync.valueOrNull ?? const [];
              final booksById = {for (final book in books) book.id: book};
              final currentBooks = _currentReadingBooks(books);
              final pendingBooks = _pendingBooks(books);

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(booksProvider);
                  ref.invalidate(statisticsSummaryProvider);
                  ref.invalidate(readingInsightsSummaryProvider);
                  ref.invalidate(
                    readingSessionsForRangeProvider(recentActivityRange),
                  );
                },
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        96,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _HomeHeader(greeting: _contextualGreeting(now)),
                          const SizedBox(height: AppSpacing.md),
                          Transform.translate(
                            offset: const Offset(0, 12),
                            child: _CurrentReadingCards(
                              books: currentBooks,
                              pendingBooks: pendingBooks,
                              onOpenProgress: (book) => _openQuickProgress(
                                context,
                                ref,
                                book,
                                recentActivityRange,
                              ),
                              onAddBook: () => _openAddBook(context),
                              onStartReading: (book) =>
                                  _startReading(context, ref, book),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _QuickMetrics(summary: summary),
                          const SizedBox(height: AppSpacing.lg),
                          _AnnualGoalCard(summary: summary),
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            title: 'Actividad reciente',
                            actionLabel: 'Ver actividad',
                            onAction: () =>
                                Navigator.pushNamed(context, '/calendar'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _RecentActivityList(
                            sessions: recentSessions,
                            booksById: booksById,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAddBook(BuildContext context) {
    Navigator.pushNamed(context, '/book/add');
  }

  Future<void> _startReading(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final now = DateTime.now();
    await ref
        .read(booksProvider.notifier)
        .updateBook(
          book.copyWith(
            status: BookStatus.reading,
            startDate: book.startDate ?? now,
            updatedAt: now,
          ),
        );
    ref.invalidate(statisticsSummaryProvider);
    ref.invalidate(readingInsightsSummaryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Has empezado "${book.title}"')));
  }

  Future<void> _openQuickProgress(
    BuildContext context,
    WidgetRef ref,
    Book book,
    DateRange recentActivityRange,
  ) async {
    final update = await showDialog<_QuickReadingUpdate>(
      context: context,
      builder: (_) => _QuickReadingDialog(book: book),
    );
    if (update == null) return;
    if (update.openDetail) {
      if (!context.mounted) return;
      Navigator.pushNamed(context, '/book/detail', arguments: book.id);
      return;
    }

    await ref
        .read(registerReadingSessionProvider)
        .call(
          RegisterReadingSessionInput(
            bookId: book.id,
            sessionDate: update.sessionDate,
            pagesRead: update.pagesAdded,
            minutes: update.minutes,
            currentPage: update.currentPage,
            totalPages: update.totalPages,
            note: null,
          ),
        );

    ref.invalidate(statisticsSummaryProvider);
    ref.invalidate(readingInsightsSummaryProvider);
    ref.invalidate(booksProvider);
    ref.invalidate(readingSessionsForRangeProvider(recentActivityRange));
    if (!context.mounted) return;
    await maybeOfferSessionCompletion(
      context: context,
      ref: ref,
      book: book,
      pagesRead: update.pagesAdded,
      explicitCurrentPage: update.currentPage,
      totalPages: update.totalPages,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progreso actualizado')));
  }

  List<Book> _currentReadingBooks(List<Book> books) {
    final readingBooks = books
        .where((book) => book.status == BookStatus.reading)
        .toList();

    readingBooks.sort((a, b) {
      final aDate = a.updatedAt ?? a.startDate ?? a.createdAt;
      final bDate = b.updatedAt ?? b.startDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return readingBooks;
  }

  List<Book> _pendingBooks(List<Book> books) {
    final pendingBooks = books
        .where((book) => book.status == BookStatus.pending)
        .toList();
    pendingBooks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pendingBooks;
  }

  String _contextualGreeting(DateTime now) {
    if (now.hour < 12) return 'Buenos dias';
    if (now.hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: AppRadii.card,
              ),
              child: Icon(AppIcons.book, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, Reader',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$greeting. Tu biblioteca te espera.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: AppRadii.card,
              ),
              child: Text(
                '+ lectura',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentReadingCards extends StatelessWidget {
  const _CurrentReadingCards({
    required this.books,
    required this.pendingBooks,
    required this.onOpenProgress,
    required this.onAddBook,
    required this.onStartReading,
  });

  final List<Book> books;
  final List<Book> pendingBooks;
  final ValueChanged<Book> onOpenProgress;
  final VoidCallback onAddBook;
  final ValueChanged<Book> onStartReading;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return _EmptyCurrentReadingCard(
        pendingBooks: pendingBooks,
        onAddBook: onAddBook,
        onStartReading: onStartReading,
      );
    }

    final primaryBook = books.first;
    final secondaryBooks = books.skip(1).take(2).toList();

    return Column(
      children: [
        _CurrentReadingHero(
          book: primaryBook,
          onOpenProgress: () => onOpenProgress(primaryBook),
        ),
        for (final book in secondaryBooks) ...[
          const SizedBox(height: AppSpacing.md),
          _CurrentReadingMiniCard(
            book: book,
            onOpenProgress: () => onOpenProgress(book),
          ),
        ],
      ],
    );
  }
}

class _CurrentReadingHero extends StatelessWidget {
  const _CurrentReadingHero({required this.book, required this.onOpenProgress});

  final Book book;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final currentBook = book;
    final theme = Theme.of(context);
    final progress = _bookProgress(currentBook);
    final progressPercent = (progress * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.card,
          onTap: onOpenProgress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BookCover(url: currentBook.coverUrl, width: 116, height: 172),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualmente leyendo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        currentBook.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontFamily: AppTypography.displayFontFamily,
                          fontFamilyFallback: AppTypography.displayFallback,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (currentBook.author?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          currentBook.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Text(
                            '$progressPercent%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _pageProgressText(currentBook),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: AppRadii.control,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: onOpenProgress,
                        icon: const Icon(AppIcons.edit),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currentBook.totalPages == null
                                ? 'Registrar avance'
                                : 'Continuar lectura',
                          ),
                        ),
                      ),
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
      return 'Actualiza paginas para ver tu avance';
    }
    return 'Pagina ${book.currentPage} / ${book.totalPages}';
  }
}

class _CurrentReadingMiniCard extends StatelessWidget {
  const _CurrentReadingMiniCard({
    required this.book,
    required this.onOpenProgress,
  });

  final Book book;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _bookProgress(book);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.card,
          onTap: onOpenProgress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _BookCover(url: book.coverUrl, width: 52, height: 72),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (book.author?.isNotEmpty == true)
                        Text(
                          book.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(value: progress),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _bookProgress(Book book) {
    final currentPage = book.currentPage;
    final totalPages = book.totalPages;
    if (currentPage == null || totalPages == null || totalPages <= 0) {
      return 0;
    }
    return (currentPage / totalPages).clamp(0, 1).toDouble();
  }
}

class _EmptyCurrentReadingCard extends StatelessWidget {
  const _EmptyCurrentReadingCard({
    required this.pendingBooks,
    required this.onAddBook,
    required this.onStartReading,
  });

  final List<Book> pendingBooks;
  final VoidCallback onAddBook;
  final ValueChanged<Book> onStartReading;

  @override
  Widget build(BuildContext context) {
    final visibleBooks = pendingBooks.take(2).toList();

    if (visibleBooks.isEmpty) {
      return EmptyStateCard(
        icon: AppIcons.library,
        title: 'Tu proxima lectura te espera',
        message: 'Anade un libro para empezar a construir tu biblioteca.',
        actionLabel: 'Anadir lectura',
        onAction: onAddBook,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.soft(Theme.of(context).colorScheme.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Elige tu proxima lectura'),
            const SizedBox(height: AppSpacing.sm),
            for (final book in visibleBooks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _BookCover(url: book.coverUrl, width: 42, height: 58),
                title: Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  book.author?.isNotEmpty == true ? book.author! : 'Pendiente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => onStartReading(book),
                  child: const Text('Empezar'),
                ),
                onTap: () => onStartReading(book),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  const _QuickMetrics({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _CompactMetricCard(
            icon: AppIcons.fire,
            value: '${summary.currentStreakDays}',
            label: 'Racha',
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            iconBackgroundColor: theme.colorScheme.onPrimary.withValues(
              alpha: 0.14,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CompactMetricCard(
            icon: AppIcons.book,
            value: '${summary.completedThisYear}',
            label: 'Este ano',
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            iconBackgroundColor: theme.colorScheme.secondary.withValues(
              alpha: 0.18,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CompactMetricCard(
            icon: AppIcons.pages,
            value: _compactNumber(summary.totalPagesRead),
            label: 'Paginas',
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onPrimary,
            iconBackgroundColor: theme.colorScheme.onPrimary.withValues(
              alpha: 0.14,
            ),
          ),
        ),
      ],
    );
  }

  String _compactNumber(int value) {
    if (value >= 1000) {
      final compact = value / 1000;
      return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
    }
    return '$value';
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconBackgroundColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.soft(backgroundColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: AppRadii.card,
              ),
              child: Icon(icon, color: foregroundColor, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor.withValues(alpha: 0.76),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnualGoalCard extends StatelessWidget {
  const _AnnualGoalCard({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final goal = summary.annualReadingGoal;
    final progress = summary.annualGoalProgress ?? 0;
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final goalValue = goal == null
        ? '${summary.completedThisYear}'
        : '${summary.completedThisYear} / $goal';
    final subtitle = goal == null
        ? 'Define un objetivo anual desde Progreso.'
        : '${(safeProgress * 100).round()}% completado';

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.flag, color: theme.colorScheme.onPrimary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Objetivo lector',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                Text(
                  goalValue,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadii.control,
              child: LinearProgressIndicator(
                value: safeProgress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.onPrimary.withValues(
                  alpha: 0.18,
                ),
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/stats'),
                child: Text(
                  'Ver objetivo',
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReadingUpdate {
  const _QuickReadingUpdate({
    required this.sessionDate,
    this.currentPage,
    this.totalPages,
    this.pagesAdded = 0,
    this.minutes = 0,
    this.openDetail = false,
  });

  final DateTime sessionDate;
  final int? currentPage;
  final int? totalPages;
  final int pagesAdded;
  final int minutes;
  final bool openDetail;
}

class _QuickReadingDialog extends StatefulWidget {
  const _QuickReadingDialog({required this.book});

  final Book book;

  @override
  State<_QuickReadingDialog> createState() => _QuickReadingDialogState();
}

class _QuickReadingDialogState extends State<_QuickReadingDialog> {
  late final TextEditingController _pagesReadController;
  late final TextEditingController _currentPageController;
  late final TextEditingController _totalPagesController;
  late final TextEditingController _minutesController;
  late DateTime _sessionDate;

  @override
  void initState() {
    super.initState();
    _sessionDate = _today();
    _pagesReadController = TextEditingController();
    _currentPageController = TextEditingController(
      text: widget.book.currentPage?.toString() ?? '',
    );
    _totalPagesController = TextEditingController(
      text: widget.book.totalPages?.toString() ?? '',
    );
    _minutesController = TextEditingController();
  }

  @override
  void dispose() {
    _pagesReadController.dispose();
    _currentPageController.dispose();
    _totalPagesController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _save() {
    final pagesRead = int.tryParse(_pagesReadController.text.trim()) ?? 0;
    final currentPageInput = int.tryParse(_currentPageController.text.trim());
    final totalPagesInput = int.tryParse(_totalPagesController.text.trim());
    final previousPage = widget.book.currentPage ?? 0;
    final currentPageWasEdited =
        currentPageInput != null && currentPageInput != previousPage;
    final currentPage = currentPageWasEdited
        ? currentPageInput
        : previousPage + pagesRead;
    final pagesAdded = pagesRead > 0
        ? pagesRead
        : currentPage > previousPage
        ? currentPage - previousPage
        : 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;

    Navigator.pop(
      context,
      _QuickReadingUpdate(
        sessionDate: _sessionDate,
        currentPage: currentPage > 0 ? currentPage : null,
        totalPages: totalPagesInput != null && totalPagesInput > 0
            ? totalPagesInput
            : null,
        pagesAdded: pagesAdded,
        minutes: minutes,
      ),
    );
  }

  Future<void> _pickSessionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2000),
      lastDate: _today(),
    );
    if (selected == null) return;
    setState(
      () =>
          _sessionDate = DateTime(selected.year, selected.month, selected.day),
    );
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AlertDialog(
      title: Text('Registrar avance', style: theme.textTheme.titleLarge),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.7),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                subtitle: Text(_formatDate(_sessionDate)),
                trailing: const Icon(AppIcons.calendar),
                onTap: _pickSessionDate,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _pagesReadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Paginas leidas'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _currentPageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pagina actual'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _totalPagesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total de paginas',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutos de lectura',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _save,
                child: const Text('Guardar cambios'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _QuickReadingUpdate(
                      sessionDate: _sessionDate,
                      openDetail: true,
                    ),
                  );
                },
                child: const Text('Ir al detalle completo del libro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.sessions, required this.booksById});

  final List<ReadingSession> sessions;
  final Map<String, Book> booksById;

  @override
  Widget build(BuildContext context) {
    final recentSessions = [...sessions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleSessions = recentSessions.take(3).toList();

    if (visibleSessions.isEmpty) {
      return EmptyStateCard(
        icon: AppIcons.time,
        title: 'Sin actividad reciente',
        message: 'Cuando registres una sesion, aparecera aqui.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            for (var index = 0; index < visibleSessions.length; index++) ...[
              _ActivityTile(
                session: visibleSessions[index],
                book: booksById[visibleSessions[index].bookId],
              ),
              if (index < visibleSessions.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.session, required this.book});

  final ReadingSession session;
  final Book? book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: _BookCover(url: book?.coverUrl, width: 40, height: 54),
      title: Text(
        book?.title ?? 'Libro no encontrado',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _activitySubtitle(session, book),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _activityValue(session),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: book == null
          ? null
          : () => Navigator.pushNamed(
              context,
              '/book/detail',
              arguments: book!.id,
            ),
    );
  }

  String _activitySubtitle(ReadingSession session, Book? book) {
    final parts = <String>[
      _formatDateTime(session.createdAt),
      if (book?.author?.isNotEmpty == true) book!.author!,
      if (session.pagesRead > 0) '${session.pagesRead} paginas',
    ];
    return parts.join(' - ');
  }

  String _activityValue(ReadingSession session) {
    final parts = <String>[
      if (session.pagesRead > 0) '${session.pagesRead} pag.',
      if (session.minutes > 0) '${session.minutes} min',
    ];
    return parts.isEmpty ? '-' : parts.join('\n');
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month} $hour:$minute';
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.card,
      ),
      child: const Icon(AppIcons.book),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: AppRadii.card,
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
