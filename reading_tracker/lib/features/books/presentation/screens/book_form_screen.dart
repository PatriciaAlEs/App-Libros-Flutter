import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/book_api_datasource.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_search_result.dart';
import '../../domain/enums/book_status.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../providers/books_provider.dart';

class BookFormScreen extends ConsumerStatefulWidget {
  const BookFormScreen({super.key});

  @override
  ConsumerState<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends ConsumerState<BookFormScreen> {
  final _searchController = TextEditingController();
  List<BookSearchResult> _results = const [];
  BookSearchResult? _selectedBook;
  BookStatus _selectedStatus = BookStatus.pending;
  bool _isSearching = false;
  bool _isSaving = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
      _selectedBook = null;
    });

    try {
      final datasource = ref.read(bookApiDatasourceProvider);
      final results = await datasource.searchBooks(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo buscar el libro. Inténtalo de nuevo.';
        _results = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _save() async {
    final selectedBook = _selectedBook;
    if (selectedBook == null) return;

    setState(() => _isSaving = true);

    final book = Book(
      id: const Uuid().v4(),
      title: selectedBook.title,
      author: selectedBook.author,
      publisher: selectedBook.publisher,
      coverUrl: selectedBook.coverUrl,
      isbn: selectedBook.isbn,
      firstPublishYear: selectedBook.firstPublishYear,
      status: _selectedStatus,
      startDate: _selectedStatus == BookStatus.reading ? DateTime.now() : null,
      completedDate: _selectedStatus == BookStatus.completed
          ? DateTime.now()
          : null,
      createdAt: DateTime.now(),
    );

    await ref.read(booksProvider.notifier).addBook(book);
    ref.invalidate(statsProvider);

    if (mounted) Navigator.pop(context, _selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir libro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchField(
            controller: _searchController,
            isSearching: _isSearching,
            onSubmitted: _search,
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedBook != null) ...[
            _SelectedBookCard(book: _selectedBook!),
            const SizedBox(height: 16),
          ],
          _InitialStatusSelector(
            selectedStatus: _selectedStatus,
            onChanged: (status) => setState(() => _selectedStatus = status),
          ),
          const SizedBox(height: 16),
          _ResultsList(
            results: _results,
            hasSearched: _hasSearched,
            selectedBook: _selectedBook,
            onSelected: (book) => setState(() => _selectedBook = book),
          ),
          const SizedBox(height: 24),
          _SaveButton(
            isSaving: _isSaving,
            enabled: _selectedBook != null,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Título, autor o ISBN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onSubmitted(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: isSearching ? null : onSubmitted,
          icon: isSearching
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: const Text('Buscar'),
        ),
      ],
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.hasSearched,
    required this.selectedBook,
    required this.onSelected,
  });

  final List<BookSearchResult> results;
  final bool hasSearched;
  final BookSearchResult? selectedBook;
  final ValueChanged<BookSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      if (!hasSearched) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No encontramos resultados. Prueba con otro título, autor o ISBN.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados de Open Library',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Algunos resultados pueden aparecer en otros idiomas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final book in results)
          Card(
            child: ListTile(
              leading: _Cover(url: book.coverUrl),
              title: Text(book.title),
              subtitle: Text(_subtitleFor(book)),
              trailing: identical(book, selectedBook)
                  ? const Icon(Icons.check_circle)
                  : null,
              selected: identical(book, selectedBook),
              onTap: () => onSelected(book),
            ),
          ),
      ],
    );
  }

  String _subtitleFor(BookSearchResult book) {
    return [
      if (book.author != null) book.author,
      if (book.publisher != null) book.publisher,
      if (book.firstPublishYear != null) '${book.firstPublishYear}',
    ].whereType<String>().join(' - ');
  }
}

class _InitialStatusSelector extends StatelessWidget {
  const _InitialStatusSelector({
    required this.selectedStatus,
    required this.onChanged,
  });

  final BookStatus selectedStatus;
  final ValueChanged<BookStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BookStatus>(
      initialValue: selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Estado inicial',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final status in BookStatus.values)
          DropdownMenuItem(value: status, child: Text(status.label)),
      ],
      onChanged: (status) {
        if (status != null) onChanged(status);
      },
    );
  }
}

class _SelectedBookCard extends StatelessWidget {
  const _SelectedBookCard({required this.book});

  final BookSearchResult book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _Cover(url: book.coverUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (book.author != null) Text(book.author!),
                if (book.publisher != null) Text(book.publisher!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: 48,
        height: 72,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.menu_book),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: 48,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 72,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.menu_book),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.enabled,
    required this.onPressed,
  });

  final bool isSaving;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled && !isSaving ? onPressed : null,
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Guardar libro'),
      ),
    );
  }
}
