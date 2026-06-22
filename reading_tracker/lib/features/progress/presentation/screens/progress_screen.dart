import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/entities/book_search_result.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../../stats/domain/entities/statistics_summary.dart';
import '../../../stats/presentation/providers/annual_goal_cover_controller.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);
    final annualGoalCover = ref.watch(annualGoalCoverControllerProvider);
    final books = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
    final sessionsAsync = ref.watch(
      readingSessionsForRangeProvider(_recentRange()),
    );
    final allTimeSessionsAsync = ref.watch(
      readingSessionsForRangeProvider(_allTimeRange()),
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
              stops: const [0, 0.40, 1],
            ),
          ),
          child: summaryAsync.when(
            loading: () => const _ProgressLoadingState(),
            error: (error, _) => const _ProgressErrorState(),
            data: (summary) {
              final activeBook = _activeReadingBook(books);
              final sessions = sessionsAsync.valueOrNull ?? const [];
              final totalMinutes =
                  (allTimeSessionsAsync.valueOrNull ?? const []).fold<int>(
                    0,
                    (total, session) => total + session.minutes,
                  );
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
                  _ProgressHeader(readerProfile: readerProfile),
                  const SizedBox(height: AppSpacing.xxl),
                  _ProgressHero(
                    summary: summary,
                    activeBook: activeBook,
                    totalMinutes: totalMinutes,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ReadingChallengeCard(
                    summary: summary,
                    cover: effectiveAnnualGoalCover,
                    onTap: () => Navigator.pushNamed(context, '/stats'),
                    onSearchCover: () =>
                        _searchAnnualGoalCover(context, ref, books),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ReadingActivityCard(
                    sessions: sessions,
                    isLoading: sessionsAsync.isLoading,
                    onCalendarTap: () =>
                        Navigator.pushNamed(context, '/calendar'),
                    onRegisterTap: () =>
                        Navigator.pushNamed(context, '/session/add'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _QuickAccessSection(
                    onStatsTap: () => Navigator.pushNamed(context, '/stats'),
                    onCalendarTap: () =>
                        Navigator.pushNamed(context, '/calendar'),
                    onSessionTap: () =>
                        Navigator.pushNamed(context, '/session/add'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _searchAnnualGoalCover(
    BuildContext context,
    WidgetRef ref,
    List<Book> books,
  ) async {
    final selectedBook = await showDialog<Book>(
      context: context,
      builder: (_) => _ProgressAnnualGoalBookPickerDialog(books: books),
    );
    if (selectedBook == null) return;

    await ref
        .read(annualGoalCoverControllerProvider.notifier)
        .selectBook(_bookToSearchResult(selectedBook));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Portada del reto actualizada')),
    );
  }
}

BookSearchResult _bookToSearchResult(Book book) {
  return BookSearchResult(
    title: book.title,
    author: book.author,
    publisher: book.publisher,
    coverUrl: book.coverUrl,
    isbn: book.isbn,
    firstPublishYear: book.firstPublishYear,
    numberOfPages: book.totalPages,
  );
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

class _ProgressAnnualGoalBookPickerDialog extends StatefulWidget {
  const _ProgressAnnualGoalBookPickerDialog({required this.books});

  final List<Book> books;

  @override
  State<_ProgressAnnualGoalBookPickerDialog> createState() =>
      _ProgressAnnualGoalBookPickerDialogState();
}

class _ProgressAnnualGoalBookPickerDialogState
    extends State<_ProgressAnnualGoalBookPickerDialog> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanQuery = _query.trim();
    final books = cleanQuery.isEmpty
        ? _recommendedBooks(widget.books)
        : _filterBooks(widget.books, cleanQuery);

    return AlertDialog(
      title: const Text('Buscar libro'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige un libro como portada de tu reto lector',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('progress_annual_goal_cover_search_field'),
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Título, autor o ISBN',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _LocalBookPickerResults(
              books: books,
              isSearching: cleanQuery.isNotEmpty,
            ),
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

List<Book> _recommendedBooks(List<Book> books) {
  final recommended = <Book>[];
  final seen = <String>{};
  final readingBooks =
      books.where((book) => book.status == BookStatus.reading).toList()
        ..sort((a, b) {
          final aDate = a.updatedAt ?? a.startDate ?? a.createdAt;
          final bDate = b.updatedAt ?? b.startDate ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
  final completedBooks =
      books.where((book) => book.status == BookStatus.completed).toList()
        ..sort((a, b) {
          final aDate = a.updatedAt ?? a.completedDate ?? a.createdAt;
          final bDate = b.updatedAt ?? b.completedDate ?? b.createdAt;
          return bDate.compareTo(aDate);
        });

  for (final book in [...readingBooks.take(3), ...completedBooks.take(1)]) {
    if (seen.add(book.id)) recommended.add(book);
  }

  return recommended.isEmpty ? books.take(6).toList() : recommended;
}

List<Book> _filterBooks(List<Book> books, String query) {
  final normalizedQuery = _normalizeBookQuery(query);
  return books.where((book) {
    final haystack = _normalizeBookQuery(
      '${book.title} ${book.author ?? ''} ${book.isbn ?? ''}',
    );
    return haystack.contains(normalizedQuery);
  }).toList();
}

String _normalizeBookQuery(String value) {
  final lower = value.toLowerCase().trim();
  final withoutAccents = lower
      .replaceAll(RegExp(r'[áàäâã]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöôõ]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c');
  return withoutAccents.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

class _LocalBookPickerResults extends StatelessWidget {
  const _LocalBookPickerResults({
    required this.books,
    required this.isSearching,
  });

  final List<Book> books;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return _CoverSearchMessage(
        icon: Icons.search_off_rounded,
        title: isSearching ? 'Sin resultados' : 'Sin libros disponibles',
        message: isSearching
            ? 'No encontramos libros de tu biblioteca para esa búsqueda.'
            : 'Añade libros a tu biblioteca para elegir portada.',
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          return _LocalBookResultTile(book: books[index]);
        },
      ),
    );
  }
}

class _LocalBookResultTile extends StatelessWidget {
  const _LocalBookResultTile({required this.book});

  final Book book;

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
                      _localBookSubtitle(book),
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
}

String _localBookSubtitle(Book book) {
  final parts = <String>[
    if (book.author?.isNotEmpty == true) book.author!,
    if (book.status == BookStatus.reading) 'Lectura actual',
    if (book.status == BookStatus.completed) 'Completado',
    if (book.coverUrl == null) 'Sin portada',
  ];
  return parts.isEmpty ? 'Libro de tu biblioteca' : parts.join(' · ');
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.readerProfile});

  final ReaderProfile readerProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadPpPageHeader(
          readerProfile: readerProfile,
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
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
          'Sigue tu ritmo, tus retos y tu actividad lectora.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressLoadingState extends StatelessWidget {
  const _ProgressLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        128,
      ),
      children: [
        Container(
          height: 104,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var index = 0; index < 3; index++) ...[
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _ProgressErrorState extends StatelessWidget {
  const _ProgressErrorState();

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
              Icon(AppIcons.chart, color: theme.colorScheme.primary, size: 36),
              const SizedBox(height: 16),
              Text(
                'No pudimos cargar tu progreso',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tus datos siguen guardados. Vuelve a intentarlo en unos segundos.',
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

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.summary,
    required this.activeBook,
    required this.totalMinutes,
  });

  final StatisticsSummary summary;
  final Book? activeBook;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.30)!;
    final accent = theme.colorScheme.secondary;

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
            'RESUMEN LECTOR',
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
                  label: summary.completedThisYear == 1
                      ? 'libro leído'
                      : 'libros leídos',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  value: _compactNumber(summary.totalPagesRead),
                  label: 'páginas',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  value: _compactNumber(totalMinutes),
                  label: 'minutos',
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
                Icon(AppIcons.book, color: accent, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lectura activa',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent.withValues(alpha: 0.92),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activeBook == null
                            ? 'Sin lectura activa por ahora'
                            : activeBook!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _ReadingChallengeCard extends StatelessWidget {
  const _ReadingChallengeCard({
    required this.summary,
    required this.cover,
    required this.onTap,
    required this.onSearchCover,
  });

  final StatisticsSummary summary;
  final AnnualGoalCover? cover;
  final VoidCallback onTap;
  final VoidCallback onSearchCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = summary.annualReadingGoal;
    final rawProgress = summary.annualGoalProgress ?? 0;
    final progress = (rawProgress / 100).clamp(0, 1).toDouble();
    final percent = rawProgress.clamp(0, 100).round();
    final remaining = summary.booksRemainingForAnnualGoal ?? 0;

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChallengeCoverFrame(cover: cover),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objetivo del reto',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      cover?.title ?? 'Selecciona un libro para tu reto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _SoftBadge(text: goal == null ? 'Sin reto' : '$percent%'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            goal == null
                ? 'Configura tu objetivo del reto para seguir tu avance lector.'
                : '${summary.completedThisYear} / $goal libros completados',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal == null ? 0 : progress,
              minHeight: 7,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.42,
              ),
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ChallengeMiniMetric(icon: '📈', value: '$percent%'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ChallengeMiniMetric(
                  icon: '✅',
                  value: '${summary.completedThisYear}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ChallengeMiniMetric(
                  icon: '🎯',
                  value: goal == null ? '-' : '$remaining',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onSearchCover,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(cover == null ? 'Buscar libro' : 'Cambiar libro'),
              ),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  goal == null ? AppIcons.flag : AppIcons.chart,
                  size: 18,
                ),
                label: Text(
                  goal == null ? 'Configurar reto' : 'Ver estadísticas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeMiniMetric extends StatelessWidget {
  const _ChallengeMiniMetric({required this.icon, required this.value});

  final String icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: theme.textTheme.titleSmall),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCoverFrame extends StatelessWidget {
  const _ChallengeCoverFrame({required this.cover});

  final AnnualGoalCover? cover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = cover?.coverUrl;
    final placeholder = Container(
      alignment: Alignment.center,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        AppIcons.book,
        color: theme.colorScheme.primary.withValues(alpha: 0.62),
        size: 24,
      ),
    );

    return Container(
      width: 64,
      height: 94,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: coverUrl == null || coverUrl.isEmpty
          ? placeholder
          : Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}

class _ReadingActivityCard extends StatelessWidget {
  const _ReadingActivityCard({
    required this.sessions,
    required this.isLoading,
    required this.onCalendarTap,
    required this.onRegisterTap,
  });

  final List<ReadingSession> sessions;
  final bool isLoading;
  final VoidCallback onCalendarTap;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = [...sessions]
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad lectora',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Calendario y sesiones para entender tu ritmo real.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _InlineAction(
                  icon: AppIcons.calendar,
                  label: 'Calendario',
                  onTap: onCalendarTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InlineAction(
                  icon: AppIcons.add,
                  label: 'Registrar',
                  onTap: onRegisterTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (recent.isEmpty)
            Text(
              'Aún no hay sesiones recientes registradas.',
              style: theme.textTheme.bodySmall,
            )
          else
            for (final session in recent.take(3))
              _SessionPreview(session: session),
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({required this.session});

  final ReadingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = [
      if (session.pagesRead > 0) '${session.pagesRead} pág.',
      if (session.minutes > 0) '${session.minutes} min',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value.isEmpty ? 'Sesión registrada' : value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _humanDate(session.date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.onStatsTap,
    required this.onCalendarTap,
    required this.onSessionTap,
  });

  final VoidCallback onStatsTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onSessionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickAccessCard(
          icon: AppIcons.chart,
          title: 'Estadísticas',
          description: 'Resumen completo de biblioteca, ritmo y valoración.',
          onTap: onStatsTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickAccessCard(
          icon: AppIcons.calendar,
          title: 'Calendario',
          description: 'Explora tus días activos y sesiones registradas.',
          onTap: onCalendarTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickAccessCard(
          icon: AppIcons.add,
          title: 'Registrar sesión',
          description: 'Añade páginas, minutos y notas a una lectura activa.',
          onTap: onSessionTap,
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
            boxShadow: AppShadows.editorial(theme.colorScheme.primary),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.28),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.primary.withValues(alpha: 0.58),
              ),
            ],
          ),
        ),
      ),
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
        color: theme.colorScheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: child,
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Book? _activeReadingBook(List<Book> books) {
  final reading = books
      .where((book) => book.status == BookStatus.reading)
      .toList();
  if (reading.isEmpty) return null;
  reading.sort((a, b) {
    final aDate = a.updatedAt ?? a.startDate ?? a.createdAt;
    final bDate = b.updatedAt ?? b.startDate ?? b.createdAt;
    return bDate.compareTo(aDate);
  });
  return reading.first;
}

DateRange _recentRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateRange(
    start: today.subtract(const Duration(days: 30)),
    end: today.add(const Duration(days: 1)),
  );
}

DateRange _allTimeRange() {
  final now = DateTime.now();
  final tomorrow = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));
  return DateRange(start: DateTime(1900), end: tomorrow);
}

String _compactNumber(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}

String _humanDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
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
