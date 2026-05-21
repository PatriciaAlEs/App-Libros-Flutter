import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../providers/books_provider.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (books) {
        Book? book;
        for (final candidate in books) {
          if (candidate.id == bookId) {
            book = candidate;
            break;
          }
        }

        if (book == null) {
          return const Scaffold(body: Center(child: Text('Book not found.')));
        }

        return _BookDetailView(book: book);
      },
    );
  }
}

class _BookDetailView extends ConsumerWidget {
  const _BookDetailView({required this.book});

  final Book book;

  Future<void> _onStatusChanged(BookStatus newStatus, WidgetRef ref) async {
    final updated = book.copyWith(
      status: newStatus,
      startDate: newStatus == BookStatus.reading
          ? DateTime.now()
          : book.startDate,
      completedDate: newStatus == BookStatus.completed
          ? DateTime.now()
          : book.completedDate,
    );

    await ref.read(booksProvider.notifier).updateBook(updated);
    ref.invalidate(statsProvider);
  }

  Future<void> _onDelete(WidgetRef ref, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteDialog(),
    );

    if (confirm == true) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
      ref.invalidate(statsProvider);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _onDelete(ref, context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoSection(book: book),
          const SizedBox(height: 24),
          _StatusSection(
            book: book,
            onStatusChanged: (status) => _onStatusChanged(status, ref),
          ),
          const SizedBox(height: 24),
          _ReaderDataSection(book: book),
          const SizedBox(height: 24),
          _DatesSection(book: book),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cover(url: book.coverUrl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: textTheme.headlineSmall),
              if (book.author != null) ...[
                const SizedBox(height: 4),
                Text(book.author!, style: textTheme.bodyLarge),
              ],
              if (book.publisher != null) ...[
                const SizedBox(height: 4),
                Text(book.publisher!, style: textTheme.bodyMedium),
              ],
              if (book.firstPublishYear != null) ...[
                const SizedBox(height: 4),
                Text('${book.firstPublishYear}', style: textTheme.bodyMedium),
              ],
              if (book.isbn != null) ...[
                const SizedBox(height: 4),
                Text('ISBN ${book.isbn}', style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.book, required this.onStatusChanged});

  final Book book;
  final ValueChanged<BookStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<BookStatus>(
          initialValue: book.status,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: BookStatus.values
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.toValue()),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null && value != book.status) {
              onStatusChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _ReaderDataSection extends StatelessWidget {
  const _ReaderDataSection({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final progress = [
      if (book.currentPage != null) '${book.currentPage}',
      if (book.totalPages != null) 'of ${book.totalPages}',
    ].join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reader data', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _DateRow(label: 'Progress', value: progress.isEmpty ? '-' : progress),
        _DateRow(
          label: 'Rating',
          value: book.rating == null ? '-' : '${book.rating}/5',
        ),
        if (book.notes != null && book.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(book.notes!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _DatesSection extends StatelessWidget {
  const _DatesSection({required this.book});

  final Book book;

  String _format(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dates', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _DateRow(label: 'Added', value: _format(book.createdAt)),
        _DateRow(label: 'Started', value: _format(book.startDate)),
        _DateRow(label: 'Finished', value: _format(book.completedDate)),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
        width: 88,
        height: 132,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.menu_book),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: 88,
        height: 132,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 88,
          height: 132,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.menu_book),
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete book'),
      content: const Text('This action cannot be undone. Continue?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
