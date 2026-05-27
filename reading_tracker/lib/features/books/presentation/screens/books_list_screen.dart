import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/app_brand.dart';
import '../../../../core/design_system/design_system.dart';
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
                theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
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

              return CustomScrollView(
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
                        _LibraryHeader(
                          totalBooks: books.length,
                          query: _query,
                          onQueryChanged: (value) {
                            setState(() => _query = value);
                          },
                          onAddBook: _openAddBook,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (featuredBook != null) ...[
                          _FeaturedReadingCard(
                            book: featuredBook,
                            onTap: () => _openBook(featuredBook),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        _EditorialFilterBar(
                          selectedStatus: _selectedStatus,
                          onChanged: (status) {
                            setState(() => _selectedStatus = status);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _CollectionHeader(count: visibleBooks.length),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                  if (visibleBooks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          112,
                        ),
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
                        112,
                      ),
                      sliver: SliverGrid.builder(
                        itemCount: visibleBooks.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 190,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.58,
                            ),
                        itemBuilder: (context, index) {
                          final book = visibleBooks[index];
                          return _BookShelfCard(
                            book: book,
                            onTap: () => _openBook(book),
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
        SnackBar(content: Text('Libro anadido como ${status.label}')),
      );
    }
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.totalBooks,
    required this.query,
    required this.onQueryChanged,
    required this.onAddBook,
  });

  final int totalBooks;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAddBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.68),
                boxShadow: AppShadows.soft(theme.colorScheme.secondary),
              ),
              child: Text(
                'dP',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontFamily: AppTypography.displayFontFamily,
                  fontFamilyFallback: AppTypography.displayFallback,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppBrand.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$totalBooks libros en tu coleccion',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.70),
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            _RoundIconButton(icon: AppIcons.add, onTap: onAddBook),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Biblioteca',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tu coleccion privada, organizada para volver a entrar en cada historia.',
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.72),
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
        color: theme.colorScheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: TextFormField(
        initialValue: query,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar por titulo, autor o genero',
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                _BookCover(url: book.coverUrl, width: 104, height: 154),
                const SizedBox(width: AppSpacing.lg),
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
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        book.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$percent%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontFamily: AppTypography.contentFontFamily,
                              fontFamilyFallback: AppTypography.contentFallback,
                              fontWeight: FontWeight.w600,
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
    required this.onChanged,
  });

  final BookStatus? selectedStatus;
  final ValueChanged<BookStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <({String label, BookStatus? status})>[
      (label: 'Todos', status: null),
      for (final status in BookStatus.values)
        (label: _filterLabel(status), status: status),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            _FilterSegment(
              label: options[index].label,
              selected: selectedStatus == options[index].status,
              onTap: () => onChanged(options[index].status),
            ),
            if (index < options.length - 1)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  String _filterLabel(BookStatus status) {
    switch (status) {
      case BookStatus.pending:
        return 'Pendientes';
      case BookStatus.reading:
        return 'Leyendo';
      case BookStatus.completed:
        return 'Completados';
      case BookStatus.paused:
        return 'Pausados';
      case BookStatus.abandoned:
        return 'Abandonados';
    }
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.50)
          : theme.colorScheme.surface.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.secondary.withValues(alpha: 0.36)
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
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
            'Coleccion',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: AppShadows.soft(theme.colorScheme.primary),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
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
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
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
              Row(
                children: [
                  Expanded(child: _StatusPill(status: book.status)),
                  if (showProgress) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (showProgress) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.44),
                    color: theme.colorScheme.secondary,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = status == BookStatus.reading;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.42)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
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
        ? 'Nada en esta estanteria'
        : hasBooks
        ? 'Esta estanteria esta tranquila'
        : 'Tu biblioteca empieza aqui';
    final message = hasSearch
        ? 'Prueba con otro titulo, autor o genero.'
        : hasBooks
        ? 'Cambia el filtro para volver a ver tu coleccion.'
        : 'Anade tu primer libro y empieza a construir una coleccion propia.';

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
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
            Icon(AppIcons.library, color: theme.colorScheme.primary, size: 34),
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
                label: const Text('Anadir libro'),
              ),
            ],
          ],
        ),
      ),
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
