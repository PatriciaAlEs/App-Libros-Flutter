import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../reading_sessions/data/repositories/reading_session_repository_provider.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../../stats/domain/stats_calculator.dart';
import '../../../stats/presentation/providers/stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final statsAsync = ref.watch(statsProvider);
    final recentSessionsAsync = ref.watch(
      readingSessionsForRangeProvider(
        DateRange(
          start: DateTime.fromMillisecondsSinceEpoch(0),
          end: DateTime.now().add(const Duration(days: 1)),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Ver biblioteca',
            icon: const Icon(Icons.library_books_outlined),
            onPressed: () => Navigator.pushNamed(context, '/books'),
          ),
          IconButton(
            tooltip: 'Ver calendario',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.pushNamed(context, '/calendar'),
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
          final currentBook = _currentReadingBook(books);
          final pendingBooks = _pendingBooks(books);
          final dashboard = _DashboardData.fromBooksAndStats(books, stats);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(booksProvider);
              ref.invalidate(statsProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.list(
                    children: [
                      _SectionHeader(
                        title: 'Lectura actual',
                        actionLabel: currentBook == null
                            ? 'Añadir libro'
                            : 'Ver detalle',
                        onAction: () {
                          if (currentBook == null) {
                            _openAddBook(context);
                          } else {
                            Navigator.pushNamed(
                              context,
                              '/book/detail',
                              arguments: currentBook.id,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _CurrentReadingCard(
                        book: currentBook,
                        pendingBooks: pendingBooks,
                        onOpenProgress: currentBook == null
                            ? null
                            : () =>
                                  _openQuickProgress(context, ref, currentBook),
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
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Añadir libro',
        onPressed: () => _openAddBook(context),
        icon: const Icon(Icons.add),
        label: const Text('Añadir libro'),
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
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Has empezado "${book.title}"')));
  }

  Future<void> _openQuickProgress(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final update = await showModalBottomSheet<_QuickReadingUpdate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _QuickReadingSheet(book: book),
    );
    if (update == null) return;
    if (update.openDetail) {
      if (!context.mounted) return;
      Navigator.pushNamed(context, '/book/detail', arguments: book.id);
      return;
    }

    final now = DateTime.now();
    await ref
        .read(booksProvider.notifier)
        .updateBook(
          book.copyWith(
            currentPage: update.currentPage ?? book.currentPage,
            updatedAt: now,
          ),
        );

    if (update.minutes > 0) {
      await ref
          .read(readingSessionRepositoryProvider)
          .addSession(
            ReadingSession(
              id: 'session-${now.microsecondsSinceEpoch}',
              bookId: book.id,
              date: now,
              minutes: update.minutes,
              createdAt: now,
            ),
          );
    }

    ref.invalidate(statsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progreso actualizado')));
  }

  Book? _currentReadingBook(List<Book> books) {
    final readingBooks = books
        .where((book) => book.status == BookStatus.reading)
        .toList();
    if (readingBooks.isEmpty) return null;

    readingBooks.sort((a, b) {
      final aDate = a.updatedAt ?? a.startDate ?? a.createdAt;
      final bDate = b.updatedAt ?? b.startDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return readingBooks.first;
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

class _CurrentReadingCard extends StatelessWidget {
  const _CurrentReadingCard({
    required this.book,
    required this.pendingBooks,
    required this.onStartReading,
    this.onOpenProgress,
  });

  final Book? book;
  final List<Book> pendingBooks;
  final ValueChanged<Book> onStartReading;
  final VoidCallback? onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentBook = book;

    if (currentBook == null) {
      return _PendingReadingSuggestions(
        books: pendingBooks,
        onStartReading: onStartReading,
      );
    }

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
                        Text(
                          'Añade el total de páginas para calcular el progreso.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
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
    return '$progressLabel · Pagina ${book.currentPage} de ${book.totalPages}';
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
    this.currentPage,
    this.minutes = 0,
    this.openDetail = false,
  });

  final int? currentPage;
  final int minutes;
  final bool openDetail;
}

class _QuickReadingSheet extends StatefulWidget {
  const _QuickReadingSheet({required this.book});

  final Book book;

  @override
  State<_QuickReadingSheet> createState() => _QuickReadingSheetState();
}

class _QuickReadingSheetState extends State<_QuickReadingSheet> {
  late final TextEditingController _pagesReadController;
  late final TextEditingController _currentPageController;
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _pagesReadController = TextEditingController();
    _currentPageController = TextEditingController(
      text: widget.book.currentPage?.toString() ?? '',
    );
    _minutesController = TextEditingController();
  }

  @override
  void dispose() {
    _pagesReadController.dispose();
    _currentPageController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _save() {
    final pagesRead = int.tryParse(_pagesReadController.text.trim()) ?? 0;
    final currentPageInput = int.tryParse(_currentPageController.text.trim());
    final currentPage =
        currentPageInput ?? (widget.book.currentPage ?? 0) + pagesRead;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;

    Navigator.pop(
      context,
      _QuickReadingUpdate(
        currentPage: currentPage > 0 ? currentPage : null,
        minutes: minutes,
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
              'Registrar avance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pagesReadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Páginas leídas hoy',
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
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos de lectura de hoy',
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
                  const _QuickReadingUpdate(openDetail: true),
                );
              },
              child: const Text('Ir al detalle completo del libro'),
            ),
          ],
        ),
      ),
    );
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
      ..sort((a, b) => b.date.compareTo(a.date));
    final visibleSessions = recentSessions.take(5).toList();

    if (visibleSessions.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aun no hay actividad. Registra una sesion para ver tu ritmo de lectura.',
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final session in visibleSessions)
          _ActivityTile(session: session, book: booksById[session.bookId]),
      ],
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
        trailing: Text('${session.minutes} min'),
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
      _formatDate(session.date),
      if (book?.author?.isNotEmpty == true) book!.author!,
      if (session.note?.isNotEmpty == true) session.note!,
    ];
    return parts.join(' · ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
