import 'package:flutter/material.dart';

import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (book.author != null && book.author!.isNotEmpty) book.author!,
      if (book.publisher != null && book.publisher!.isNotEmpty) book.publisher!,
      if (book.firstPublishYear != null) '${book.firstPublishYear}',
      if (book.status == BookStatus.reading && _progressText != null)
        _progressText!,
      if (book.status == BookStatus.completed && book.rating != null)
        'Valoracion ${_formatRating(book.rating!)} / 5',
    ].join(' - ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: _BookCover(url: book.coverUrl),
        title: Text(book.title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: _StatusChip(status: book.status),
        onTap: onTap,
      ),
    );
  }

  String? get _progressText {
    if (book.currentPage == null || book.totalPages == null) return null;
    if (book.totalPages! <= 0) return null;
    final percentage = ((book.currentPage! / book.totalPages!) * 100).clamp(
      0,
      100,
    );
    return 'Pagina ${book.currentPage} de ${book.totalPages} (${percentage.round()}%)';
  }

  String _formatRating(double rating) {
    return rating.toStringAsFixed(rating % 1 == 0 ? 1 : 2);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isReading = status == BookStatus.reading;

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.label),
      side: BorderSide(
        color: isReading ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      backgroundColor: isReading
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isReading
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: 42,
        height: 56,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.menu_book),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: 42,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 42,
          height: 56,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.menu_book),
        ),
      ),
    );
  }
}
