import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';
import '../providers/books_provider.dart';

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  BookStatus? _selectedStatus;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);
    final booksAsync = ref.watch(booksProvider);

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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                const Center(child: Text('No se pudieron cargar los libros.')),
            data: (books) {
              final filteredBooks = _filteredBooks(books);
              final visibleBooks = _selectedStatus == null
                  ? _readingBooksFirst(filteredBooks)
                  : filteredBooks;
              final featuredBook = _featuredReadingBook(books);
              final collectionCount = _countForStatus(books);
              final libraryStats = _LibraryStats.fromBooks(books);

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _LibraryHeader(
                          stats: libraryStats,
                          query: _query,
                          readerProfile: readerProfile,
                          onAddBook: _openAddBook,
                          onQueryChanged: (value) {
                            setState(() => _query = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (featuredBook != null) ...[
                          _FeaturedReadingCard(
                            book: featuredBook,
                            onTap: () => _openBook(featuredBook),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                        _EditorialFilterBar(
                          selectedStatus: _selectedStatus,
                          stats: libraryStats,
                          onChanged: (status) {
                            setState(() => _selectedStatus = status);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _CollectionHeader(count: collectionCount),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                  if (visibleBooks.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        112,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _BooksEmptyState(
                          hasBooks: books.isNotEmpty,
                          hasSearch: _query.trim().isNotEmpty,
                          onAddBook: _openAddBook,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        136,
                      ),
                      sliver: SliverGrid.builder(
                        itemCount: visibleBooks.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 190,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18,
                              childAspectRatio: 0.58,
                            ),
                        itemBuilder: (context, index) {
                          final book = visibleBooks[index];
                          return _AnimatedBookCard(
                            index: index,
                            child: _BookShelfCard(
                              book: book,
                              onTap: () => _openBook(book),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Book> _filteredBooks(List<Book> books) {
    final query = _query.trim().toLowerCase();
    return books.where((book) {
      final matchesStatus =
          _selectedStatus == null || book.status == _selectedStatus;
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final searchable = [
        book.title,
        if (book.author?.isNotEmpty == true) book.author!,
        if (book.genre?.isNotEmpty == true) book.genre!,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Book? _featuredReadingBook(List<Book> books) {
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

  List<Book> _readingBooksFirst(List<Book> books) {
    final readingBooks = books
        .where((book) => book.status == BookStatus.reading)
        .toList();
    final otherBooks = books
        .where((book) => book.status != BookStatus.reading)
        .toList();
    return [...readingBooks, ...otherBooks];
  }

  int _countForStatus(List<Book> books) {
    final status = _selectedStatus;
    if (status == null) return books.length;
    return books.where((book) => book.status == status).length;
  }

  Future<void> _openBook(Book book) async {
    final deleted = await Navigator.pushNamed(
      context,
      '/book/detail',
      arguments: book.id,
    );
    if (!mounted) return;
    if (deleted == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Libro eliminado')));
    }
  }

  Future<void> _openAddBook() async {
    final status = await Navigator.pushNamed(context, '/book/add');
    if (!mounted) return;
    if (status is BookStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Libro añadido como ${status.label}')),
      );
    }
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.stats,
    required this.query,
    required this.readerProfile,
    required this.onAddBook,
    required this.onQueryChanged,
  });

  final _LibraryStats stats;
  final String query;
  final ReaderProfile readerProfile;
  final VoidCallback onAddBook;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBrandHeader(
          readerProfile: readerProfile,
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          },
          onProfileTap: () => Navigator.pushNamed(context, '/settings'),
          onAddBookTap: onAddBook,
          onCalendarTap: () => Navigator.pushNamed(context, '/calendar'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${stats.totalBooks} libros en tu colección',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SearchField(query: query, onChanged: onQueryChanged),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: query,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Busca un libro, autora o género',
          hintStyle: theme.textTheme.bodySmall,
          prefixIcon: Icon(AppIcons.search, color: theme.colorScheme.primary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

class _FeaturedReadingCard extends StatelessWidget {
  const _FeaturedReadingCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _bookProgress(book);
    final percent = (progress * 100).round();
    final primary = theme.colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.32)!;
    final accent = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, dark],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.20),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BookCover(url: book.coverUrl, width: 116, height: 174),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LECTURA ACTUAL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent.withValues(alpha: 0.94),
                          letterSpacing: 2.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        book.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          textStyle: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 31,
                            fontWeight: FontWeight.w700,
                            height: 1.04,
                          ),
                        ),
                      ),
                      if (book.author?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          book.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accent.withValues(alpha: 0.95),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$percent%',
                            style: GoogleFonts.cormorantGaramond(
                              textStyle: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                _pageProgress(book),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.74,
                                  ),
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
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          color: accent.withValues(alpha: 0.96),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(AppIcons.book, size: 18),
                        label: const Text('Ver lectura'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface,
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
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
}

class _EditorialFilterBar extends StatelessWidget {
  const _EditorialFilterBar({
    required this.selectedStatus,
    required this.stats,
    required this.onChanged,
  });

  final BookStatus? selectedStatus;
  final _LibraryStats stats;
  final ValueChanged<BookStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <({String label, BookStatus? status})>[
      (label: 'Todos', status: null),
      (label: 'Leyendo', status: BookStatus.reading),
      (label: 'Pendientes', status: BookStatus.pending),
      (label: 'Terminados', status: BookStatus.completed),
    ];
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              _FilterSegment(
                label: options[index].label,
                count: stats.countFor(options[index].status),
                selected: selectedStatus == options[index].status,
                onTap: () => onChanged(options[index].status),
              ),
              if (index < options.length - 1)
                const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.secondary.withValues(alpha: 0.36)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.secondary.withValues(alpha: 0.34)
                      : theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.34,
                        ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 10,
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

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            'Colección',
            style: GoogleFonts.cormorantGaramond(
              textStyle: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                height: 1.08,
              ),
            ),
          ),
        ),
        Text(
          '$count libros',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.76),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _BookShelfCard extends StatelessWidget {
  const _BookShelfCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _bookProgress(book);
    final showProgress = book.status == BookStatus.reading && progress > 0;
    final statusColor = _statusColor(theme, book.status);

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
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: _BookCover(
                        url: book.coverUrl,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _BookStatusBadge(status: book.status, color: statusColor),
              const SizedBox(height: AppSpacing.sm),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppTypography.contentFontFamily,
                  fontFamilyFallback: AppTypography.contentFallback,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
              if (book.author?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  book.author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
              if (showProgress) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _pageProgress(book),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.72),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.38),
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, BookStatus status) {
    switch (status) {
      case BookStatus.reading:
        return theme.colorScheme.secondary;
      case BookStatus.completed:
        return theme.colorScheme.primary;
      case BookStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case BookStatus.paused:
        return theme.colorScheme.tertiary;
      case BookStatus.abandoned:
        return theme.colorScheme.error;
    }
  }
}

class _BooksEmptyState extends StatelessWidget {
  const _BooksEmptyState({
    required this.hasBooks,
    required this.hasSearch,
    required this.onAddBook,
  });

  final bool hasBooks;
  final bool hasSearch;
  final VoidCallback onAddBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = hasSearch
        ? 'No encontramos ese libro'
        : hasBooks
        ? 'Esta estantería está tranquila'
        : 'Tu biblioteca empieza aquí';
    final message = hasSearch
        ? 'Prueba con otro título, autora o género.'
        : hasBooks
        ? 'Cambia el filtro o añade una nueva lectura.'
        : 'Añade tu primer libro y empieza a construir una colección propia.';

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
          boxShadow: AppShadows.soft(theme.colorScheme.primary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.28),
              ),
              child: Icon(
                hasSearch ? AppIcons.search : AppIcons.library,
                color: theme.colorScheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (!hasBooks) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAddBook,
                icon: const Icon(AppIcons.add),
                label: const Text('Añadir primer libro'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookStatusBadge extends StatelessWidget {
  const _BookStatusBadge({required this.status, required this.color});

  final BookStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        _statusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _statusLabel(BookStatus status) {
    switch (status) {
      case BookStatus.reading:
        return 'Leyendo';
      case BookStatus.completed:
        return 'Terminado';
      case BookStatus.pending:
        return 'Pendiente';
      case BookStatus.paused:
        return 'Pausado';
      case BookStatus.abandoned:
        return 'Abandonado';
    }
  }
}

class _AnimatedBookCard extends StatelessWidget {
  const _AnimatedBookCard({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (index.clamp(0, 5) * 35)),
      curve: AppMotion.standard,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
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
    final theme = Theme.of(context);
    final placeholder = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(AppIcons.book, color: theme.colorScheme.primary),
    );

    if (url == null || url!.isEmpty) return placeholder;

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

String _pageProgress(Book book) {
  if (book.currentPage == null || book.totalPages == null) {
    return 'Progreso por registrar';
  }
  return '${book.currentPage} / ${book.totalPages} p.';
}

class _LibraryStats {
  const _LibraryStats({
    required this.totalBooks,
    required this.readingBooks,
    required this.pendingBooks,
    required this.completedBooks,
  });

  final int totalBooks;
  final int readingBooks;
  final int pendingBooks;
  final int completedBooks;

  factory _LibraryStats.fromBooks(List<Book> books) {
    return _LibraryStats(
      totalBooks: books.length,
      readingBooks: books
          .where((book) => book.status == BookStatus.reading)
          .length,
      pendingBooks: books
          .where((book) => book.status == BookStatus.pending)
          .length,
      completedBooks: books
          .where((book) => book.status == BookStatus.completed)
          .length,
    );
  }

  int countFor(BookStatus? status) {
    if (status == null) return totalBooks;
    switch (status) {
      case BookStatus.reading:
        return readingBooks;
      case BookStatus.pending:
        return pendingBooks;
      case BookStatus.completed:
        return completedBooks;
      case BookStatus.paused:
      case BookStatus.abandoned:
        return 0;
    }
  }
}
