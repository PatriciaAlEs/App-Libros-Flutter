import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
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
    final readerProfile = ref.watch(readerProfileControllerProvider);
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.46, 1],
            ),
          ),
          child: booksAsync.when(
            loading: () => const _HomeLoadingState(),
            error: (error, _) => const _HomeErrorState(),
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
                        112,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _HomeHeader(
                            greetingText: readerProfile.homeGreeting(now),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (currentBooks.length > 1) ...[
                            _CurrentReadingSwitcher(
                              books: _prioritizeCurrentBooks(
                                currentBooks,
                                readerProfile.currentReadingBookId,
                              ),
                              onChange: () => _showCurrentReadingPicker(
                                context,
                                ref,
                                _prioritizeCurrentBooks(
                                  currentBooks,
                                  readerProfile.currentReadingBookId,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          _CurrentReadingCards(
                            books: _prioritizeCurrentBooks(
                              currentBooks,
                              readerProfile.currentReadingBookId,
                            ),
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
                          const SizedBox(height: AppSpacing.xxl),
                          _QuickMetrics(
                            summary: summary,
                            onOpenCalendar: () =>
                                Navigator.pushNamed(context, '/calendar'),
                            onOpenLibrary: () =>
                                Navigator.pushNamed(context, '/books'),
                            onOpenProgress: () =>
                                Navigator.pushNamed(context, '/progress'),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _AnnualGoalCard(
                            summary: summary,
                            onTap: () =>
                                Navigator.pushNamed(context, '/progress'),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _JournalHeader(
                            onSeeAll: () =>
                                Navigator.pushNamed(context, '/calendar'),
                          ),
                          const SizedBox(height: AppSpacing.md),
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
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        112,
      ),
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 302,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var index = 0; index < 3; index++) ...[
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState();

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
              Icon(AppIcons.home, color: theme.colorScheme.primary, size: 36),
              const SizedBox(height: 16),
              Text(
                'No pudimos preparar tu inicio',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tus lecturas siguen guardadas. Inténtalo de nuevo en unos segundos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.greetingText});

  final String greetingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppBrandHeader(
                  showGreeting: false,
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  ),
                ),
              ),
              _HeaderActionButton(
                icon: AppIcons.profile,
                tooltip: 'Perfil',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$greetingText 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/book/add'),
                  icon: const Icon(AppIcons.add, size: 18),
                  label: const Text('Libro'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/calendar'),
                  icon: const Icon(AppIcons.calendar, size: 18),
                  label: const Text('Calendario'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.68),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READING JOURNAL',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.74),
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Actividad reciente',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('Abrir calendario')),
      ],
    );
  }
}

class _CurrentReadingSwitcher extends StatelessWidget {
  const _CurrentReadingSwitcher({required this.books, required this.onChange});

  final List<Book> books;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            '¿Qué estás leyendo?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '1 / ${books.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton(onPressed: onChange, child: const Text('Cambiar libro')),
      ],
    );
  }
}

void _showCurrentReadingPicker(
  BuildContext context,
  WidgetRef ref,
  List<Book> books,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _CurrentReadingPicker(books: books, ref: ref),
  );
}

class _CurrentReadingPicker extends StatelessWidget {
  const _CurrentReadingPicker({required this.books, required this.ref});

  final List<Book> books;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        shrinkWrap: true,
        children: [
          Text(
            'Cambiar libro',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Elige qué libro quieres destacar en la Home.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final book in books) ...[
            _CurrentReadingPickerTile(
              book: book,
              onSelected: () {
                ref
                    .read(readerProfileControllerProvider.notifier)
                    .updateCurrentReadingBookId(book.id);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _CurrentReadingPickerTile extends StatelessWidget {
  const _CurrentReadingPickerTile({
    required this.book,
    required this.onSelected,
  });

  final Book book;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _bookProgress(book);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          _MiniBookCover(book: book),
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
                if (book.author?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(value: progress),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton(onPressed: onSelected, child: const Text('Elegir')),
        ],
      ),
    );
  }
}

class _MiniBookCover extends StatelessWidget {
  const _MiniBookCover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return Container(
        width: 48,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(AppIcons.book),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        coverUrl,
        width: 48,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 70,
          alignment: Alignment.center,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(AppIcons.book),
        ),
      ),
    );
  }
}

List<Book> _prioritizeCurrentBooks(List<Book> books, String? selectedBookId) {
  final prioritized = [...books];
  final selectedIndex = selectedBookId == null
      ? -1
      : prioritized.indexWhere((book) => book.id == selectedBookId);

  if (selectedIndex > 0) {
    final selected = prioritized.removeAt(selectedIndex);
    prioritized.insert(0, selected);
    return prioritized;
  }
  if (selectedIndex == 0) return prioritized;

  prioritized.sort((a, b) => _bookProgress(b).compareTo(_bookProgress(a)));
  return prioritized;
}

double _bookProgress(Book book) {
  final totalPages = book.totalPages;
  if (totalPages == null || totalPages <= 0) return 0;
  return ((book.currentPage ?? 0) / totalPages).clamp(0.0, 1.0).toDouble();
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
    final primary = theme.colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.34)!;
    final onDark = theme.colorScheme.onPrimary;
    final accent = theme.colorScheme.secondary;
    final genre = currentBook.genre?.trim();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, dark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.20),
            blurRadius: 36,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onOpenProgress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LECTURA ACTUAL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent.withValues(alpha: 0.92),
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (genre != null && genre.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.44),
                          ),
                        ),
                        child: Text(
                          genre.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent.withValues(alpha: 0.98),
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 340;
                    final cover = _BookCover(
                      url: currentBook.coverUrl,
                      width: isNarrow ? 112 : 132,
                      height: isNarrow ? 168 : 198,
                      radius: 16,
                    );

                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentBook.title,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: onDark,
                            fontFamily: AppTypography.displayFontFamily,
                            fontFamilyFallback: AppTypography.displayFallback,
                            fontSize: isNarrow ? 26 : 31,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (currentBook.author?.isNotEmpty == true)
                          Text(
                            currentBook.author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: accent.withValues(alpha: 0.94),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 30),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$progressPercent',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: onDark,
                                fontFamily: AppTypography.contentFontFamily,
                                fontFamilyFallback:
                                    AppTypography.contentFallback,
                                fontSize: isNarrow ? 42 : 48,
                                fontWeight: FontWeight.w600,
                                height: 0.92,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 7,
                              ),
                              child: Text(
                                '%',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: accent.withValues(alpha: 0.96),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  _pageProgressText(currentBook),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: onDark.withValues(alpha: 0.78),
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
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            color: accent.withValues(alpha: 0.96),
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: cover),
                          const SizedBox(height: AppSpacing.lg),
                          details,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cover,
                        const SizedBox(width: 22),
                        Expanded(child: details),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: onOpenProgress,
                  icon: const Icon(AppIcons.book),
                  label: Text(
                    currentBook.totalPages == null
                        ? 'Registrar avance'
                        : 'Continuar lectura',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
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
      return 'Progreso por registrar';
    }
    return '${book.currentPage} / ${book.totalPages} p.';
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
    final primary = theme.colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.22)!;
    final accent = theme.colorScheme.secondary;
    final onDark = theme.colorScheme.onPrimary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.92),
            dark.withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onOpenProgress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _BookCover(
                  url: book.coverUrl,
                  width: 52,
                  height: 72,
                  radius: 12,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onDark,
                          fontFamily: AppTypography.contentFontFamily,
                          fontFamilyFallback: AppTypography.contentFallback,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (book.author?.isNotEmpty == true)
                        Text(
                          book.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onDark.withValues(alpha: 0.72),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
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
        title: 'Tu primer libro empieza aquí',
        message: 'Añade una lectura para construir tu biblioteca personal.',
        actionLabel: 'Añadir primer libro',
        onAction: onAddBook,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.soft(Theme.of(context).colorScheme.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Elige tu próxima lectura'),
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
  const _QuickMetrics({
    required this.summary,
    required this.onOpenCalendar,
    required this.onOpenLibrary,
    required this.onOpenProgress,
  });

  final StatisticsSummary summary;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenProgress;

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
            footnote: 'días',
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            iconColor: theme.colorScheme.primary,
            onTap: onOpenCalendar,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CompactMetricCard(
            icon: AppIcons.book,
            value: '${summary.completedThisYear}',
            label: 'Libros',
            footnote: 'este año',
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            iconColor: theme.colorScheme.primary,
            onTap: onOpenLibrary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CompactMetricCard(
            icon: AppIcons.pages,
            value: _compactNumber(summary.totalPagesRead),
            label: 'Páginas',
            footnote: 'totales',
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            iconColor: theme.colorScheme.primary,
            onTap: onOpenProgress,
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
    required this.footnote,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String footnote;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.42,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: foregroundColor,
                          fontFamily: AppTypography.contentFontFamily,
                          fontFamilyFallback: AppTypography.contentFallback,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          footnote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnualGoalCard extends StatelessWidget {
  const _AnnualGoalCard({required this.summary, required this.onTap});

  final StatisticsSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final goal = summary.annualReadingGoal;
    final progress = summary.annualGoalProgress ?? 0;
    final safeProgress = (progress / 100).clamp(0.0, 1.0).toDouble();
    final subtitle = goal == null
        ? 'Configura tu reto lector desde Progreso.'
        : (summary.booksRemainingForAnnualGoal != null &&
              summary.booksRemainingForAnnualGoal! > 0)
        ? '${summary.booksRemainingForAnnualGoal} más para alcanzar la estantería'
        : 'Objetivo anual alcanzado';

    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.09),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$year READING GOAL',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.78,
                              ),
                              letterSpacing: 2.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Reto de lectura $year',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
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
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${(safeProgress * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${summary.completedThisYear}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontFamily: AppTypography.contentFontFamily,
                        fontFamilyFallback: AppTypography.contentFallback,
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        goal == null ? 'libros' : '/ $goal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      AppIcons.star,
                      color: theme.colorScheme.secondary,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.82),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: safeProgress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.42),
                    color: theme.colorScheme.primary.withValues(alpha: 0.74),
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
                decoration: const InputDecoration(labelText: 'Páginas leídas'),
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
                  labelText: 'Total de páginas',
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
      ..sort((a, b) => b.date.compareTo(a.date));
    final visibleSessions = recentSessions.take(3).toList();

    if (visibleSessions.isEmpty) {
      return EmptyStateCard(
        icon: AppIcons.time,
        title: 'Tu diario lector está tranquilo',
        message: 'Cuando registres páginas o minutos, aparecerán aquí.',
      );
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
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
                Divider(
                  height: 1,
                  indent: 82,
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      leading: _BookCover(
        url: book?.coverUrl,
        width: 50,
        height: 68,
        radius: 11,
      ),
      title: Text(
        book?.title ?? 'Libro no encontrado',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: AppTypography.contentFontFamily,
          fontFamilyFallback: AppTypography.contentFallback,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        _activitySubtitle(session, book),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary.withValues(alpha: 0.78),
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Text(
        _relativeDate(session.date),
        textAlign: TextAlign.right,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary.withValues(alpha: 0.82),
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
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
      if (session.pagesRead > 0) '${session.pagesRead} páginas',
      if (session.minutes > 0) '${session.minutes} min',
      if (book?.author?.isNotEmpty == true) book!.author!,
    ];
    return parts.isEmpty ? 'Sesión registrada' : parts.join(' · ');
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(sessionDay).inDays;
    if (difference <= 0) return 'HOY';
    if (difference == 1) return 'AYER';
    if (difference < 7) return 'HACE $difference DÍAS';
    return _humanDate(date).toUpperCase();
  }

  String _humanDate(DateTime date) {
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
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.url,
    required this.width,
    required this.height,
    this.radius = AppRadii.lg,
  });

  final String? url;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverShadow = [
      BoxShadow(
        color: theme.colorScheme.secondary.withValues(alpha: 0.34),
        blurRadius: 24,
        spreadRadius: 1,
        offset: const Offset(0, 10),
      ),
    ];
    final placeholder = _CoverShell(
      width: width,
      height: height,
      radius: radius,
      shadows: coverShadow,
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(AppIcons.book),
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return _CoverShell(
      width: width,
      height: height,
      radius: radius,
      shadows: coverShadow,
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

class _CoverShell extends StatelessWidget {
  const _CoverShell({
    required this.width,
    required this.height,
    required this.radius,
    required this.shadows,
    required this.child,
  });

  final double width;
  final double height;
  final double radius;
  final List<BoxShadow> shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}
