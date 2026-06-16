import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.18),
                theme.colorScheme.primaryContainer.withValues(alpha: 0.24),
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.40, 1],
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
              final todaySessions = _todaySessions(recentSessions);
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
                        AppSpacing.lg,
                        AppSpacing.lg,
                        132,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _HomeHeader(readerProfile: readerProfile),
                          const SizedBox(height: AppSpacing.xl),
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
                          if (currentBooks.length > 1) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _CurrentReadingStrip(
                              books: _prioritizeCurrentBooks(
                                currentBooks,
                                readerProfile.currentReadingBookId,
                              ),
                              selectedBookId:
                                  readerProfile.currentReadingBookId,
                              onSelect: (book) => ref
                                  .read(
                                    readerProfileControllerProvider.notifier,
                                  )
                                  .updateCurrentReadingBookId(book.id),
                            ),
                          ],
                          const SizedBox(height: 28),
                          _TodaySummaryCard(sessions: todaySessions),
                          const SizedBox(height: 30),
                          _QuickMetrics(
                            summary: summary,
                            onOpenCalendar: () =>
                                Navigator.pushNamed(context, '/calendar'),
                            onOpenLibrary: () =>
                                Navigator.pushNamed(context, '/books'),
                            onOpenProgress: () =>
                                Navigator.pushNamed(context, '/progress'),
                          ),
                          const SizedBox(height: 28),
                          _AnnualGoalCard(
                            summary: summary,
                            onTap: () =>
                                Navigator.pushNamed(context, '/progress'),
                          ),
                          const SizedBox(height: 32),
                          _WeeklyCalendarPreview(
                            sessions: recentSessions,
                            onTap: () =>
                                Navigator.pushNamed(context, '/calendar'),
                          ),
                          const SizedBox(height: 30),
                          const _JournalHeader(),
                          const SizedBox(height: AppSpacing.lg),
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

  List<ReadingSession> _todaySessions(List<ReadingSession> sessions) {
    final now = DateTime.now();
    return sessions
        .where(
          (session) =>
              session.date.year == now.year &&
              session.date.month == now.month &&
              session.date.day == now.day,
        )
        .toList();
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
  const _HomeHeader({required this.readerProfile});

  final ReaderProfile readerProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = readerProfile.homeGreeting(DateTime.now());
    final commaIndex = greeting.indexOf(',');
    final greetingLead = commaIndex == -1
        ? greeting
        : greeting.substring(0, commaIndex + 1);
    final greetingName = commaIndex == -1
        ? 'Lectora'
        : greeting.substring(commaIndex + 1).trim();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _HomeBrandLogo(),
                  const Spacer(),
                  _HeaderActionButton(
                    icon: AppIcons.profile,
                    tooltip: 'Perfil',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttons = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HomePillButton(
                        icon: AppIcons.add,
                        label: 'Libro',
                        onTap: () => Navigator.pushNamed(context, '/book/add'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HomePillButton(
                        icon: AppIcons.calendar,
                        label: 'Calendario',
                        onTap: () => Navigator.pushNamed(context, '/calendar'),
                      ),
                    ],
                  );

                  final greeting = RichText(
                    text: TextSpan(
                      style: GoogleFonts.cormorantGaramond(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.88,
                          ),
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                      children: [
                        TextSpan(text: '$greetingLead\n'),
                        TextSpan(
                          text: '$greetingName 👋',
                          style: GoogleFonts.cormorantGaramond(
                            textStyle: theme.textTheme.displaySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (constraints.maxWidth < 390) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        greeting,
                        const SizedBox(height: AppSpacing.md),
                        Align(alignment: Alignment.centerRight, child: buttons),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: greeting),
                      const SizedBox(width: AppSpacing.md),
                      buttons,
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeBrandLogo extends StatelessWidget {
  const _HomeBrandLogo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 184,
      height: 68,
      child: Image.asset(
        AppBrand.headerLogoAsset,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppBrand.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomePillButton extends StatelessWidget {
  const _HomePillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
  const _JournalHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Actividad reciente',
      style: GoogleFonts.cormorantGaramond(
        textStyle: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
          fontWeight: FontWeight.w700,
        ),
      ),
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
    return _CurrentReadingHero(
      book: primaryBook,
      onOpenProgress: () => onOpenProgress(primaryBook),
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

    return Container(
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
          onTap: onOpenProgress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 350;
                final cover = _BookCover(
                  url: currentBook.coverUrl,
                  width: isNarrow ? 112 : 148,
                  height: isNarrow ? 168 : 220,
                  radius: 12,
                );

                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Text(
                          'LECTURA ACTUAL',
                          style: GoogleFonts.cormorantGaramond(
                            textStyle: theme.textTheme.labelSmall?.copyWith(
                              color: accent.withValues(alpha: 0.95),
                              letterSpacing: 1.1,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isNarrow ? AppSpacing.md : 18),
                    Text(
                      currentBook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cormorantGaramond(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: onDark,
                          fontSize: isNarrow ? 25 : 32,
                          fontWeight: FontWeight.w700,
                          height: 1.02,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (currentBook.author?.isNotEmpty == true)
                      Text(
                        currentBook.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onDark.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                    SizedBox(height: isNarrow ? AppSpacing.lg : 28),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$progressPercent%',
                        style: GoogleFonts.cormorantGaramond(
                          textStyle: theme.textTheme.titleLarge?.copyWith(
                            color: onDark,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 13,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        color: accent.withValues(alpha: 1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _pageProgressText(currentBook),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onDark.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.schedule_rounded,
                          color: onDark.withValues(alpha: 0.82),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Registrar',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onDark.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenProgress,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(
                          currentBook.totalPages == null
                              ? 'Registrar avance'
                              : 'Continuar lectura',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: onDark,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.13),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: cover),
                      const SizedBox(height: AppSpacing.lg),
                      details,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    cover,
                    const SizedBox(width: 30),
                    Expanded(child: details),
                  ],
                );
              },
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

class _CurrentReadingStrip extends StatefulWidget {
  const _CurrentReadingStrip({
    required this.books,
    required this.selectedBookId,
    required this.onSelect,
  });

  final List<Book> books;
  final String? selectedBookId;
  final ValueChanged<Book> onSelect;

  @override
  State<_CurrentReadingStrip> createState() => _CurrentReadingStripState();
}

class _CurrentReadingStripState extends State<_CurrentReadingStrip> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _selectedIndex();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.86,
    );
  }

  @override
  void didUpdateWidget(covariant _CurrentReadingStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPage = _selectedIndex();
    if (nextPage != _currentPage) {
      _currentPage = nextPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _selectedIndex() {
    if (widget.books.isEmpty) return 0;
    final selectedBookId = widget.selectedBookId;
    if (selectedBookId == null) return 0;
    final index = widget.books.indexWhere((book) => book.id == selectedBookId);
    return index == -1 ? 0 : index;
  }

  void _selectPage(int index, {bool animate = false}) {
    if (index < 0 || index >= widget.books.length) return;
    setState(() => _currentPage = index);
    widget.onSelect(widget.books[index]);
    if (animate && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) return const SizedBox.shrink();

    return _HomeSectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeSectionTitle(title: 'Lecturas en curso'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 124,
            child: PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none,
              padEnds: false,
              physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
              itemCount: widget.books.length,
              onPageChanged: _selectPage,
              itemBuilder: (context, index) {
                final book = widget.books[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.books.length - 1 ? 0 : AppSpacing.md,
                  ),
                  child: _CurrentReadingChip(
                    book: book,
                    isSelected: index == _currentPage,
                    onTap: () => _selectPage(index, animate: true),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.books.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CurrentReadingChip extends StatelessWidget {
  const _CurrentReadingChip({
    required this.book,
    required this.isSelected,
    required this.onTap,
  });

  final Book book;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _bookProgress(book);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [primary, Color.lerp(primary, Colors.black, 0.20)!]
                  : [
                      theme.colorScheme.surface.withValues(alpha: 0.92),
                      theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.22,
                      ),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.secondary.withValues(alpha: 0.38)
                  : theme.colorScheme.secondary.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isSelected ? 0.16 : 0.07),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _BookCover(url: book.coverUrl, width: 54, height: 78, radius: 12),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author ?? 'Autor desconocido',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary.withValues(
                                alpha: 0.72,
                              )
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
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
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.sessions});

  final List<ReadingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final pages = sessions.fold<int>(
      0,
      (total, session) => total + session.pagesRead,
    );
    final minutes = sessions.fold<int>(
      0,
      (total, session) => total + session.minutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HomeSectionTitle(title: 'Resumen de hoy'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _TodayMetric(
                icon: AppIcons.pages,
                label: 'Páginas leídas',
                value: '$pages',
                footnote: 'páginas',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TodayMetric(
                icon: AppIcons.time,
                label: 'Tiempo de lectura',
                value: '$minutes',
                footnote: 'minutos',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TodayMetric(
                icon: AppIcons.calendar,
                label: 'Sesiones',
                value: '${sessions.length}',
                footnote: 'sesiones',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.footnote,
  });

  final IconData icon;
  final String label;
  final String value;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cormorantGaramond(
              textStyle: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 0.92,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            footnote,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCalendarPreview extends StatelessWidget {
  const _WeeklyCalendarPreview({required this.sessions, required this.onTap});

  final List<ReadingSession> sessions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    final activityByDay = <DateTime, int>{};
    for (final session in sessions) {
      final key = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      activityByDay[key] =
          (activityByDay[key] ?? 0) + session.pagesRead + session.minutes;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _HomeSectionTitle(title: 'Book Journal')),
            TextButton(onPressed: onTap, child: const Text('Abrir calendario')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: _WeekDayPill(
                      day: day,
                      isToday: _isSameDay(day, today),
                      activity: activityByDay[day] ?? 0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({
    required this.day,
    required this.isToday,
    required this.activity,
  });

  final DateTime day;
  final bool isToday;
  final int activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intensity = activity <= 0
        ? 0.0
        : activity < 30
        ? 0.22
        : activity < 90
        ? 0.42
        : 0.68;
    final fill = isToday
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary.withValues(alpha: intensity + 0.12);
    final textColor = isToday
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: isToday ? 0.0 : 0.14,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekdayLabel(day),
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: isToday ? 0.82 : 0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${day.day}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isToday
                  ? theme.colorScheme.onPrimary
                  : activity > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(DateTime day) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return labels[day.weekday - 1];
  }
}

class _HomeSectionSurface extends StatelessWidget {
  const _HomeSectionSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useSans = title == 'Resumen de hoy';

    final style = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
      fontWeight: FontWeight.w600,
      height: 1.1,
    );

    return Text(
      title,
      style: useSans
          ? style?.copyWith(fontSize: 15.5)
          : GoogleFonts.cormorantGaramond(
              textStyle: style?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
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
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.78),
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
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.78),
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
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.78),
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
          height: 94,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (label == 'Racha')
                      Text(
                        '🔥',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 25,
                          height: 1,
                        ),
                      )
                    else
                      Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
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
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          textStyle: theme.textTheme.titleLarge?.copyWith(
                            color: foregroundColor,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 0.90,
                          ),
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
                            fontWeight: FontWeight.w500,
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
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Reto anual',
                                style: GoogleFonts.cormorantGaramond(
                                  textStyle: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(safeProgress * 100).round()}%',
                                style: GoogleFonts.cormorantGaramond(
                                  textStyle: theme.textTheme.displaySmall
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w700,
                                        height: 0.92,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(
                                    goal == null
                                        ? '${summary.completedThisYear} libros'
                                        : '${summary.completedThisYear} de $goal libros',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.76,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: safeProgress,
                              minHeight: 8,
                              backgroundColor: theme
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.52),
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.84,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            width: double.infinity,
                            height: 42,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.62,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Ver progreso anual',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
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
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.07),
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
        vertical: AppSpacing.sm,
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
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        _activitySubtitle(session, book),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary.withValues(alpha: 0.66),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _relativeDate(session.date),
          textAlign: TextAlign.right,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.66),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
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
