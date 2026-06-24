import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../../../../core/analytics/readpp_analytics.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../entities/reading_session.dart';
import '../repositories/reading_session_repository.dart';

class RegisterReadingSession {
  const RegisterReadingSession({
    required ReadingSessionRepository sessionRepository,
    required BookRepository bookRepository,
    ReadPpAnalytics analytics = const ReadPpAnalytics.disabled(),
    Uuid uuid = const Uuid(),
  }) : _sessionRepository = sessionRepository,
       _bookRepository = bookRepository,
       _analytics = analytics,
       _uuid = uuid;

  final ReadingSessionRepository _sessionRepository;
  final BookRepository _bookRepository;
  final ReadPpAnalytics _analytics;
  final Uuid _uuid;

  Future<ReadingSession?> call(RegisterReadingSessionInput input) async {
    final book = await _bookRepository.getBookById(input.bookId);
    if (book == null) {
      throw StateError('Book not found: ${input.bookId}');
    }

    final now = input.createdAt ?? DateTime.now();
    final normalizedDate = DateTime(
      input.sessionDate.year,
      input.sessionDate.month,
      input.sessionDate.day,
    );
    final pagesRead = math.max(0, input.pagesRead);
    final minutes = math.max(0, input.minutes);
    final totalPages = input.totalPages ?? book.totalPages;
    final currentPage = _calculateCurrentPage(
      book: book,
      pagesRead: pagesRead,
      explicitCurrentPage: input.currentPage,
      totalPages: totalPages,
    );

    if (_shouldUpdateBook(book, currentPage, totalPages)) {
      await _bookRepository.updateBook(
        book.copyWith(
          currentPage: currentPage,
          totalPages: totalPages,
          updatedAt: now,
        ),
      );
    }

    if (pagesRead == 0 && minutes == 0) {
      return null;
    }

    final session = ReadingSession(
      id: _uuid.v4(),
      bookId: input.bookId,
      date: normalizedDate,
      minutes: minutes,
      pagesRead: pagesRead,
      note: input.note?.trim().isEmpty == true ? null : input.note?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _sessionRepository.addSession(session);
    await _analytics.trackReadingSessionCreated(
      minutes: minutes,
      pagesRead: pagesRead,
    );
    return session;
  }

  int? _calculateCurrentPage({
    required Book book,
    required int pagesRead,
    required int? explicitCurrentPage,
    required int? totalPages,
  }) {
    final previousPage = book.currentPage ?? 0;
    final calculatedPage = explicitCurrentPage ?? previousPage + pagesRead;
    if (calculatedPage <= 0) return null;
    if (totalPages == null || totalPages <= 0) return calculatedPage;
    return math.min(calculatedPage, totalPages);
  }

  bool _shouldUpdateBook(Book book, int? currentPage, int? totalPages) {
    return currentPage != book.currentPage || totalPages != book.totalPages;
  }
}

class RegisterReadingSessionInput {
  const RegisterReadingSessionInput({
    required this.bookId,
    required this.sessionDate,
    this.pagesRead = 0,
    this.minutes = 0,
    this.note,
    this.currentPage,
    this.totalPages,
    this.createdAt,
  });

  final String bookId;
  final DateTime sessionDate;
  final int pagesRead;
  final int minutes;
  final String? note;
  final int? currentPage;
  final int? totalPages;
  final DateTime? createdAt;
}
