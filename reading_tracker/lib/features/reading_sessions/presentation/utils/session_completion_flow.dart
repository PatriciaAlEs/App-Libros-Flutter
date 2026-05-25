import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../books/presentation/widgets/completion_review_sheet.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';

Future<void> maybeOfferSessionCompletion({
  required BuildContext context,
  required WidgetRef ref,
  required Book book,
  required int pagesRead,
  int? explicitCurrentPage,
  int? totalPages,
}) async {
  final reachedEnd = _sessionReachedBookEnd(
    book: book,
    pagesRead: pagesRead,
    explicitCurrentPage: explicitCurrentPage,
    totalPages: totalPages,
  );
  if (!reachedEnd) return;

  final shouldComplete = await showDialog<bool>(
    context: context,
    builder: (_) => const _SessionCompletionDialog(),
  );
  if (shouldComplete != true || !context.mounted) return;

  final effectiveTotalPages = totalPages ?? book.totalPages!;
  final now = DateTime.now();
  var completedBook = book.copyWith(
    status: BookStatus.completed,
    currentPage: effectiveTotalPages,
    totalPages: effectiveTotalPages,
    completedDate: book.completedDate ?? now,
    updatedAt: now,
  );

  await ref.read(booksProvider.notifier).updateBook(completedBook);
  _invalidateCompletionProviders(ref);

  if (!context.mounted) return;
  final review = await showModalBottomSheet<CompletionReview>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CompletionReviewSheet(
      title: book.title,
      initialRating: book.rating,
      initialNote: book.notes,
    ),
  );

  if (review == null || !review.hasContent) return;

  completedBook = Book(
    id: completedBook.id,
    title: completedBook.title,
    author: completedBook.author,
    totalPages: completedBook.totalPages,
    currentPage: completedBook.currentPage,
    rating: review.rating,
    notes: review.note,
    publisher: completedBook.publisher,
    coverUrl: completedBook.coverUrl,
    isbn: completedBook.isbn,
    firstPublishYear: completedBook.firstPublishYear,
    genre: completedBook.genre,
    language: completedBook.language,
    status: completedBook.status,
    startDate: completedBook.startDate,
    completedDate: completedBook.completedDate,
    createdAt: completedBook.createdAt,
    updatedAt: DateTime.now(),
  );

  await ref.read(booksProvider.notifier).updateBook(completedBook);
  _invalidateCompletionProviders(ref);
}

bool _sessionReachedBookEnd({
  required Book book,
  required int pagesRead,
  required int? explicitCurrentPage,
  required int? totalPages,
}) {
  final effectiveTotalPages = totalPages ?? book.totalPages;
  if (book.status == BookStatus.completed) return false;
  if (effectiveTotalPages == null || effectiveTotalPages <= 0) return false;
  if (pagesRead <= 0) return false;

  final previousPage = book.currentPage ?? 0;
  if (previousPage >= effectiveTotalPages) return false;

  final calculatedPage = explicitCurrentPage ?? previousPage + pagesRead;
  if (calculatedPage <= 0) return false;

  final updatedCurrentPage = math.min(calculatedPage, effectiveTotalPages);
  return updatedCurrentPage >= effectiveTotalPages;
}

void _invalidateCompletionProviders(WidgetRef ref) {
  ref.invalidate(booksProvider);
  ref.invalidate(statsProvider);
  ref.invalidate(statisticsSummaryProvider);
  ref.invalidate(readingInsightsSummaryProvider);
}

class _SessionCompletionDialog extends StatelessWidget {
  const _SessionCompletionDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Has llegado al final del libro'),
      content: const Text('¿Quieres marcarlo como completado?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Completar libro'),
        ),
      ],
    );
  }
}
