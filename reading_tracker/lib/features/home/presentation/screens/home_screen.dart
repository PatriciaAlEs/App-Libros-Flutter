import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/domain/usecases/register_reading_session.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../../reading_sessions/presentation/providers/register_reading_session_provider.dart';
import '../../../reading_sessions/presentation/utils/session_completion_flow.dart';
import '../../../stats/domain/stats_calculator.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onOpenLibrary,
    this.onOpenProgress,
    this.onOpenInsights,
  });

  final VoidCallback? onOpenLibrary;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenInsights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final statsAsync = ref.watch(statsProvider);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final recentActivityRange = DateRange(
      start: todayStart,
      end: todayStart.add(const Duration(days: 1)),
    );
    final recentSessionsAsync = ref.watch(
      readingSessionsForRangeProvider(recentActivityRange),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Ver biblioteca',
            icon: const Icon(Icons.auto_stories_outlined),
            onPressed:
                onOpenLibrary ?? (() => Navigator.pushNamed(context, '/books')),
          ),
          IconButton(
            tooltip: 'Ver progreso',
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed:
                onOpenProgress ??
                (() => Navigator.pushNamed(context, '/progress')),
          ),
          IconButton(
            tooltip: 'Ver insights',
            icon: const Icon(Icons.insights_outlined),
            onPressed:
                onOpenInsights ??
                (() => Navigator.pushNamed(context, '/insights')),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('No se pudo cargar el inicio.')),
        data: (books) {
          final stats = statsAsync.valueOrNull;
          final recentSessions = recentSessionsAsync.valueOrNull ?? const [];
          final booksById = {for (final book in books) book.id: book};
          final currentBooks = _currentReadingBooks(books);
          final pendingBooks = _pendingBooks(books);
          final dashboard = _DashboardData.fromBooksAndStats(books, stats);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(booksProvider);
              ref.invalidate(statsProvider);
              ref.invalidate(statisticsSummaryProvider);
              ref.invalidate(readingInsightsSummaryProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.list(
                    children: [
                      _SectionHeader(
                        title: 'Lectura actual',
                        actionLabel: currentBooks.isEmpty
                            ? 'Añadir libro'
                            : 'Ver biblioteca',
                        onAction: () {
                          if (currentBooks.isEmpty) {
                            _openAddBook(context);
                          } else {
                            if (onOpenLibrary != null) {
                              onOpenLibrary!();
                            } else {
                              Navigator.pushNamed(context, '/books');
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _CurrentReadingSection(
                        books: currentBooks,
                        pendingBooks: pendingBooks,
                        onOpenProgress: (book) => _openQuickProgress(
                          context,
                          ref,
                          book,
                          recentActivityRange,
                        ),
                        onStartReading: (book) =>
                            _startReading(context, ref, book),
                      ),
                      const SizedBox(height: 12),
                      _AddBookCtaCard(onPressed: () => _openAddBook(context)),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Resumen rapido'),
                      const SizedBox(height: 8),
                      _QuickStatsGrid(data: dashboard),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Actividad reciente',
                        actionLabel: 'Registrar',
                        onAction: () => Navigator.pushNamed(
                          context,
                          '/session/add',
                          arguments: DateTime.now(),
                        ),
                      ),
                      const SizedBox(height: 8),
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
    ref.invalidate(statsProvider);
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

    ref.invalidate(statsProvider);
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

class _DashboardData {
  const _DashboardData({
    required this.booksReadThisYear,
    required this.pagesRead,
    required this.averageRating,
  });

  final int booksReadThisYear;
  final int pagesRead;
  final double? averageRating;

  factory _DashboardData.fromBooksAndStats(List<Book> books, StatsData? stats) {
    final currentYear = DateTime.now().year;
    final ratedBooks = books.where((book) => book.rating != null).toList();
    final averageRating = ratedBooks.isEmpty
        ? null
        : ratedBooks.fold<double>(0, (sum, book) => sum + book.rating!) /
              ratedBooks.length;

    return _DashboardData(
      booksReadThisYear: books.where((book) {
        final completedDate = book.completedDate;
        return completedDate != null && completedDate.year == currentYear;
      }).length,
      pagesRead: stats?.pagesRead ?? _fallbackPagesRead(books),
      averageRating: averageRating,
    );
  }

  static int _fallbackPagesRead(List<Book> books) {
    return books.fold<int>(0, (sum, book) {
      if (book.status == BookStatus.completed && book.totalPages != null) {
        return sum + book.totalPages!;
      }
      return sum + (book.currentPage ?? 0);
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _AddBookCtaCard extends StatelessWidget {
  const _AddBookCtaCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.add),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Añadir nuevo libro',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Busca en Open Library o crea una nueva lectura.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentReadingSection extends StatelessWidget {
  const _CurrentReadingSection({
    required this.books,
    required this.pendingBooks,
    required this.onOpenProgress,
    required this.onStartReading,
  });

  final List<Book> books;
  final List<Book> pendingBooks;
  final ValueChanged<Book> onOpenProgress;
  final ValueChanged<Book> onStartReading;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return _PendingReadingSuggestions(
        books: pendingBooks,
        onStartReading: onStartReading,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < books.length; index++) ...[
          _CurrentReadingCard(
            book: books[index],
            onOpenProgress: () => onOpenProgress(books[index]),
          ),
          if (index < books.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CurrentReadingCard extends StatelessWidget {
  const _CurrentReadingCard({required this.book, required this.onOpenProgress});

  final Book book;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentBook = book;
    final progress = _bookProgress(currentBook);
    final progressLabel = '${(progress * 100).round()}%';

    return Semantics(
      button: true,
      label:
          'Libro actual ${currentBook.title}. Progreso de lectura $progressLabel. Toca para registrar avance.',
      child: Card(
        elevation: 0,
        color: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onOpenProgress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BookCover(url: currentBook.coverUrl, width: 72, height: 104),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentBook.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (currentBook.author?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentBook.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (currentBook.totalPages == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: onOpenProgress,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Añadir total de páginas'),
                          ),
                        )
                      else ...[
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text(
                          _progressText(currentBook, progressLabel),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Registrar avance',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
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

  String _progressText(Book book, String progressLabel) {
    if (book.currentPage == null) {
      return 'Actualiza la página actual para ver tu avance.';
    }
    return '$progressLabel · Página ${book.currentPage} de ${book.totalPages}';
  }
}

class _PendingReadingSuggestions extends StatelessWidget {
  const _PendingReadingSuggestions({
    required this.books,
    required this.onStartReading,
  });

  final List<Book> books;
  final ValueChanged<Book> onStartReading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleBooks = books.take(3).toList();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Quieres empezar alguna de tus lecturas pendientes?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (visibleBooks.isEmpty)
              const Text('Añade libros pendientes para tener sugerencias aquí.')
            else
              for (final book in visibleBooks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _BookCover(
                    url: book.coverUrl,
                    width: 42,
                    height: 56,
                  ),
                  title: Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    book.author?.isNotEmpty == true
                        ? book.author!
                        : 'Pendiente desde ${_formatDate(book.createdAt)}',
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  bool get hasReadingActivity => pagesAdded > 0 || minutes > 0;

  String? get activityNote {
    final parts = <String>[
      if (pagesAdded > 0) '$pagesAdded páginas añadidas',
      if (currentPage != null) 'Página actual $currentPage',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
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
      title: Text(
        'Registrar avance',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
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
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                subtitle: Text(_formatDate(_sessionDate)),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickSessionDate,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pagesReadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Páginas leídas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currentPageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Página actual',
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
              const SizedBox(height: 12),
              TextField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutos de lectura',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: const Text('Guardar cambios'),
              ),
              const SizedBox(height: 8),
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

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final rating = data.averageRating == null
        ? '-'
        : data.averageRating!.toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth >= 640 ? 2.5 : 1.35,
          children: [
            _MetricCard(
              icon: Icons.emoji_events_outlined,
              label: 'Leidos este año',
              value: '${data.booksReadThisYear}',
            ),
            _MetricCard(
              icon: Icons.menu_book_outlined,
              label: 'Paginas leidas',
              value: '${data.pagesRead}',
            ),
            _MetricCard(
              icon: Icons.star_border,
              label: 'Valoracion media',
              value: rating,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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

    if (recentSessions.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aún no hay actividad hoy. Registra una sesión para ver tu ritmo de lectura.',
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: recentSessions.length,
        itemBuilder: (context, index) {
          final session = recentSessions[index];
          return _ActivityTile(
            session: session,
            book: booksById[session.bookId],
          );
        },
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _BookCover(url: book?.coverUrl, width: 42, height: 56),
        title: Text(
          book?.title ?? 'Libro no encontrado',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _activitySubtitle(session, book),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(_activityValue(session)),
        onTap: book == null
            ? null
            : () => Navigator.pushNamed(
                context,
                '/book/detail',
                arguments: book!.id,
              ),
      ),
    );
  }

  String _activitySubtitle(ReadingSession session, Book? book) {
    final parts = <String>[
      _formatDateTime(session.createdAt),
      if (book?.author?.isNotEmpty == true) book!.author!,
      if (session.pagesRead > 0) '${session.pagesRead} paginas leidas',
      if (session.note?.isNotEmpty == true) session.note!,
    ];
    return parts.join(' · ');
  }

  String _activityValue(ReadingSession session) {
    final parts = <String>[
      if (session.pagesRead > 0) '${session.pagesRead} pag.',
      if (session.minutes > 0) '${session.minutes} min',
    ];
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.menu_book_outlined),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
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
