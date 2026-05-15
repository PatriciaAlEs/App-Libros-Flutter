import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/book.dart';
import '../../domain/models/book_status.dart';
import '../providers/books_provider.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (books) {
        final book = books.where((b) => b.id == bookId).firstOrNull;

        if (book == null) {
          return const Scaffold(
            body: Center(child: Text('Book not found.')),
          );
        }

        return _BookDetailView(book: book);
      },
    );
  }
}

// ── Vista principal ──────────────────────────────────────
class _BookDetailView extends ConsumerWidget {
  const _BookDetailView({required this.book});

  final Book book;

  Future<void> _onStatusChanged(
    BookStatus newStatus,
    WidgetRef ref,
    BuildContext context,
  ) async {
    final updated = book.copyWith(
      status: newStatus,
      startDate: newStatus == BookStatus.reading
          ? DateTime.now()
          : book.startDate,
      endDate: newStatus == BookStatus.completed
          ? DateTime.now()
          : book.endDate,
    );

    await ref.read(booksProvider.notifier).updateBook(updated);
  }

  Future<void> _onDelete(WidgetRef ref, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteDialog(),
    );

    if (confirm == true) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
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
            onStatusChanged: (status) =>
                _onStatusChanged(status, ref, context),
          ),
          const SizedBox(height: 24),
          _DatesSection(book: book),
        ],
      ),
    );
  }
}

// ── Sección: Info ────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(book.title, style: textTheme.headlineSmall),
        if (book.author != null) ...[
          const SizedBox(height: 4),
          Text(book.author!, style: textTheme.bodyLarge),
        ],
        if (book.pages != null) ...[
          const SizedBox(height: 4),
          Text('${book.pages} pages', style: textTheme.bodyMedium),
        ],
      ],
    );
  }
}

// ── Sección: Estado ──────────────────────────────────────
class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.book,
    required this.onStatusChanged,
  });

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
          value: book.status,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: BookStatus.values
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.toValue()),
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

// ── Sección: Fechas ──────────────────────────────────────
class _DatesSection extends StatelessWidget {
  const _DatesSection({required this.book});

  final Book book;

  String _format(DateTime? date) {
    if (date == null) return '—';
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
        _DateRow(label: 'Finished', value: _format(book.endDate)),
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

// ── Diálogo eliminar ─────────────────────────────────────
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