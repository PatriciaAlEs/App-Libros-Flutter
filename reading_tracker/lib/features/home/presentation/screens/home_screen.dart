import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../books/presentation/widgets/current_reading_card.dart';
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
                theme.colorScheme.primaryContainer.withValues(alpha: 0.14),
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.44, 1],
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
              final currentReadingBookId = _resolvedCurrentReadingBookId(
                currentBooks,
                readerProfile.currentReadingBookId,
              );
              _syncCurrentReadingPreference(
                ref,
                readerProfile.currentReadingBookId,
                currentReadingBookId,
              );
              final prioritizedCurrentBooks = _prioritizeCurrentBooks(
                currentBooks,
                currentReadingBookId,
              );
              final otherCurrentBooks = currentBooks
                  .where((book) => book.id != currentReadingBookId)
                  .toList();
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
                        132,
                      ),
                      sliver: SliverList.list(
                        children: [
                          ReadPpPageHeader(
                            readerProfile: readerProfile,
                            onTap: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                            onProfileTap: () =>
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/settings',
                                  (_) => false,
                                ),
                            onAddBookTap: () =>
                                Navigator.pushNamed(context, '/book/add'),
                            onCalendarTap: () =>
                                Navigator.pushNamed(context, '/calendar'),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _CurrentReadingCards(
                            books: prioritizedCurrentBooks,
                            pendingBooks: pendingBooks,
                            currentReadingBookId: currentReadingBookId,
                            onChangeCurrentReading: () =>
                                _showCurrentReadingPicker(
                                  context,
                                  ref,
                                  prioritizedCurrentBooks,
                                ),
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
                          if (otherCurrentBooks.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _CurrentReadingStrip(
                              books: otherCurrentBooks,
                              onBookTap: (book) => _openQuickProgress(
                                context,
                                ref,
                                book,
                                recentActivityRange,
                              ),
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
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/books',
                                  (_) => false,
                                ),
                            onOpenProgress: () =>
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/progress',
                                  (_) => false,
                                ),
                          ),
                          const SizedBox(height: 28),
                          _AnnualGoalCard(
                            summary: summary,
                            onTap: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/progress',
                              (_) => false,
                            ),
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

  String? _resolvedCurrentReadingBookId(
    List<Book> currentBooks,
    String? storedBookId,
  ) {
    if (currentBooks.isEmpty) return null;
    if (storedBookId != null &&
        currentBooks.any((book) => book.id == storedBookId)) {
      return storedBookId;
    }
    return currentBooks.first.id;
  }

  void _syncCurrentReadingPreference(
    WidgetRef ref,
    String? storedBookId,
    String? resolvedBookId,
  ) {
    if (storedBookId == resolvedBookId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(readerProfileControllerProvider.notifier);
      if (resolvedBookId == null) {
        controller.clearCurrentReadingBookId();
      } else {
        controller.updateCurrentReadingBookId(resolvedBookId);
      }
    });
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

// ignore: unused_element
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
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/settings',
                      (_) => false,
                    ),
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.88,
                        ),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                      children: [
                        TextSpan(text: '$greetingLead\n'),
                        TextSpan(
                          text: '$greetingName 👋',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      greeting,
                      const SizedBox(height: AppSpacing.md),
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
      child: AppPressable(
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
        child: AppPressable(
          borderRadius: BorderRadius.circular(999),
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
      style: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

// ignore: unused_element
class _CurrentReadingSwitcher extends StatelessWidget {
  const _CurrentReadingSwitcher({
    required this.currentIndex,
    required this.total,
    required this.onChange,
  });

  final int currentIndex;
  final int total;
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
            '$currentIndex / $total',
            key: const Key('current_reading_position_indicator'),
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

class _CurrentReadingCards extends StatefulWidget {
  const _CurrentReadingCards({
    required this.books,
    required this.pendingBooks,
    required this.currentReadingBookId,
    required this.onChangeCurrentReading,
    required this.onOpenProgress,
    required this.onAddBook,
    required this.onStartReading,
  });

  final List<Book> books;
  final List<Book> pendingBooks;
  final String? currentReadingBookId;
  final VoidCallback onChangeCurrentReading;
  final ValueChanged<Book> onOpenProgress;
  final VoidCallback onAddBook;
  final ValueChanged<Book> onStartReading;

  @override
  State<_CurrentReadingCards> createState() => _CurrentReadingCardsState();
}

class _CurrentReadingCardsState extends State<_CurrentReadingCards> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _selectedIndex();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant _CurrentReadingCards oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.books.isEmpty) {
      _currentPage = 0;
      return;
    }

    final selectedBookChanged =
        oldWidget.currentReadingBookId != widget.currentReadingBookId;
    final bookOrderChanged = !_sameBookOrder(oldWidget.books, widget.books);

    if (selectedBookChanged) {
      _moveToPage(_selectedIndex());
      return;
    }

    if (bookOrderChanged) {
      final visibleBookId = _currentPage < oldWidget.books.length
          ? oldWidget.books[_currentPage].id
          : null;
      final nextPage = visibleBookId == null
          ? _currentPage.clamp(0, widget.books.length - 1)
          : widget.books.indexWhere((book) => book.id == visibleBookId);
      _moveToPage(
        nextPage == -1
            ? _currentPage.clamp(0, widget.books.length - 1)
            : nextPage,
        animate: false,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _selectedIndex() {
    if (widget.books.isEmpty) return 0;
    final currentReadingBookId = widget.currentReadingBookId;
    if (currentReadingBookId == null) return 0;
    final index = widget.books.indexWhere(
      (book) => book.id == currentReadingBookId,
    );
    return index == -1 ? 0 : index;
  }

  bool _sameBookOrder(List<Book> oldBooks, List<Book> newBooks) {
    if (oldBooks.length != newBooks.length) return false;
    for (var index = 0; index < oldBooks.length; index++) {
      if (oldBooks[index].id != newBooks[index].id) return false;
    }
    return true;
  }

  void _moveToPage(int page, {bool animate = true}) {
    final nextPage = page.clamp(0, widget.books.length - 1);
    if (nextPage == _currentPage) return;
    _currentPage = nextPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      if (animate) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _pageController.jumpToPage(nextPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight =
        334.0 + ((textScale - 1).clamp(0.0, 1.0).toDouble() * 72);

    if (widget.books.isEmpty) {
      return _EmptyCurrentReadingCard(
        pendingBooks: widget.pendingBooks,
        onAddBook: widget.onAddBook,
        onStartReading: widget.onStartReading,
      );
    }

    if (widget.books.length == 1) {
      final primaryBook = widget.books.first;
      return SizedBox(
        height: cardHeight,
        child: AppAnimatedPageSwitch(
          child: CurrentReadingCard(
            key: ValueKey('current-reading-${primaryBook.id}'),
            book: primaryBook,
            currentIndex: 1,
            totalReadings: 1,
            onTap: () => widget.onOpenProgress(primaryBook),
          ),
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 350;
            return SizedBox(
              height: cardHeight - (isNarrow ? 2 : 0),
              child: PageView.builder(
                key: const Key('current_reading_cards_page_view'),
                controller: _pageController,
                physics: const BouncingScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                itemCount: widget.books.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final book = widget.books[index];
                  return _CurrentReadingCardMotion(
                    controller: _pageController,
                    pageIndex: index,
                    child: CurrentReadingCard(
                      key: ValueKey('current-reading-${book.id}'),
                      book: book,
                      isPrimaryReading: book.id == widget.currentReadingBookId,
                      currentIndex: index + 1,
                      totalReadings: widget.books.length,
                      onChangeCurrentReading: widget.onChangeCurrentReading,
                      onTap: () => widget.onOpenProgress(book),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CurrentReadingCardMotion extends StatelessWidget {
  const _CurrentReadingCardMotion({
    required this.controller,
    required this.pageIndex,
    required this.child,
  });

  final PageController controller;
  final int pageIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        var page = pageIndex.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? pageIndex.toDouble();
        }
        final distance = (page - pageIndex).abs().clamp(0.0, 1.0);
        final opacity = 1 - (distance * 0.22);
        final dx = (pageIndex - page) * 18;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
    );
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
                trailing: FilledButton(
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
  const _CurrentReadingStrip({required this.books, required this.onBookTap});

  final List<Book> books;
  final ValueChanged<Book> onBookTap;

  @override
  State<_CurrentReadingStrip> createState() => _CurrentReadingStripState();
}

class _CurrentReadingStripState extends State<_CurrentReadingStrip> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.80,
    );
  }

  @override
  void didUpdateWidget(covariant _CurrentReadingStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameBookOrder(oldWidget.books, widget.books)) return;

    final visibleBookId = _currentPage < oldWidget.books.length
        ? oldWidget.books[_currentPage].id
        : null;
    final nextPage = visibleBookId == null
        ? _currentPage.clamp(0, widget.books.length - 1)
        : widget.books.indexWhere((book) => book.id == visibleBookId);
    _currentPage = nextPage == -1
        ? _currentPage.clamp(0, widget.books.length - 1)
        : nextPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(_currentPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _sameBookOrder(List<Book> oldBooks, List<Book> newBooks) {
    if (oldBooks.length != newBooks.length) return false;
    for (var index = 0; index < oldBooks.length; index++) {
      if (oldBooks[index].id != newBooks[index].id) return false;
    }
    return true;
  }

  void _showPage(int index, {bool animate = false}) {
    if (index < 0 || index >= widget.books.length) return;
    setState(() => _currentPage = index);
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
          Text(
            'Otras lecturas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.88),
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 124,
            child: PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none,
              padEnds: false,
              physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
              itemCount: widget.books.length,
              onPageChanged: (index) => _showPage(index),
              itemBuilder: (context, index) {
                final book = widget.books[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.books.length - 1
                        ? AppSpacing.xl
                        : AppSpacing.xxl,
                  ),
                  child: _CurrentReadingChip(
                    book: book,
                    isSelected: index == _currentPage,
                    onTap: () {
                      _showPage(index, animate: true);
                      widget.onBookTap(book);
                    },
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
                value: '$pages',
                unit: 'pág.',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TodayMetric(
                icon: AppIcons.time,
                value: '$minutes',
                unit: 'min',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TodayMetric(
                icon: AppIcons.calendar,
                value: '${sessions.length}',
                unit: 'sesiones',
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
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 23),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 0.92,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              unit,
              maxLines: 1,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
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
            Icon(
              AppIcons.calendar,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onTap,
                    child: _WeekDayPill(
                      day: day,
                      isToday: _isSameDay(day, today),
                      activity: activityByDay[day] ?? 0,
                    ),
                  ),
                ),
              ),
          ],
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

    final style = theme.textTheme.headlineSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
      fontWeight: FontWeight.w700,
      height: 1.1,
    );

    return Text(title, style: style);
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
            title: 'Racha',
            iconText: '🔥',
            value: '${summary.currentStreakDays}',
            unit: summary.currentStreakDays == 1 ? 'día' : 'días',
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.78),
            foregroundColor: theme.colorScheme.onSurface,
            onTap: onOpenCalendar,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CompactMetricCard(
            title: 'Libros',
            iconText: '📖',
            value: '${summary.completedThisYear}',
            unit: '',
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.78),
            foregroundColor: theme.colorScheme.onSurface,
            onTap: onOpenLibrary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CompactMetricCard(
            title: 'Páginas',
            iconText: '📄',
            value: _compactNumber(summary.totalPagesRead),
            unit: 'pág.',
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.78),
            foregroundColor: theme.colorScheme.onSurface,
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
    required this.title,
    required this.iconText,
    required this.value,
    required this.unit,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String title;
  final String iconText;
  final String value;
  final String unit;
  final Color backgroundColor;
  final Color foregroundColor;
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
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      iconText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              value,
                              maxLines: 1,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: foregroundColor,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 0.92,
                              ),
                            ),
                            if (unit.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  unit,
                                  maxLines: 1,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
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
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  height: 0.92,
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
      if (session.pagesRead > 0) '${session.pagesRead} pág.',
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
