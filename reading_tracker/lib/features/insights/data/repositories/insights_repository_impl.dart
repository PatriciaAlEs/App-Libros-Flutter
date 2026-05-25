import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/insights/domain/entities/reading_insights_summary.dart';
import 'package:reading_tracker/features/insights/domain/repositories/insights_repository.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  const InsightsRepositoryImpl({
    required BookRepository bookRepository,
    required ReadingSessionRepository readingSessionRepository,
  }) : _bookRepository = bookRepository,
       _readingSessionRepository = readingSessionRepository;

  final BookRepository _bookRepository;
  final ReadingSessionRepository _readingSessionRepository;

  @override
  Future<ReadingInsightsSummary> getSummary() async {
    final books = await _bookRepository.getAllBooks();
    if (books.isEmpty) return const ReadingInsightsSummary.empty();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final sessions = await _readingSessionRepository.getSessionsInRange(
      DateTime.fromMillisecondsSinceEpoch(0),
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );

    return _calculateSummary(books, sessions);
  }

  ReadingInsightsSummary _calculateSummary(
    List<Book> books,
    List<ReadingSession> sessions,
  ) {
    final booksById = {for (final book in books) book.id: book};
    final pagesByBookId = <String, int>{};
    final pagesByAuthor = <String, int>{};
    final pagesByGenre = <String, int>{};

    for (final session in sessions) {
      if (session.pagesRead <= 0) continue;
      final book = booksById[session.bookId];
      if (book == null) continue;

      pagesByBookId.update(
        book.id,
        (pages) => pages + session.pagesRead,
        ifAbsent: () => session.pagesRead,
      );

      final author = _cleanValue(book.author);
      if (author != null) {
        pagesByAuthor.update(
          author,
          (pages) => pages + session.pagesRead,
          ifAbsent: () => session.pagesRead,
        );
      }

      final genre = _cleanValue(book.genre);
      if (genre != null) {
        pagesByGenre.update(
          genre,
          (pages) => pages + session.pagesRead,
          ifAbsent: () => session.pagesRead,
        );
      }
    }

    final topBookEntry = _topEntry(pagesByBookId);
    final topBook = topBookEntry == null ? null : booksById[topBookEntry.key];
    final topAuthorEntry = _topEntry(pagesByAuthor);
    final topGenreEntry = _topEntry(pagesByGenre);

    return ReadingInsightsSummary(
      mostReadBookTitle: topBook?.title,
      mostReadBookPages: topBookEntry?.value ?? 0,
      mostReadAuthor: topAuthorEntry?.key,
      mostReadAuthorPages: topAuthorEntry?.value ?? 0,
      favoriteGenre: topGenreEntry?.key,
      favoriteGenrePages: topGenreEntry?.value ?? 0,
    );
  }

  MapEntry<String, int>? _topEntry(Map<String, int> pagesByKey) {
    if (pagesByKey.isEmpty) return null;

    final entries = pagesByKey.entries.toList()
      ..sort((a, b) {
        final pagesComparison = b.value.compareTo(a.value);
        if (pagesComparison != 0) return pagesComparison;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return entries.first;
  }

  String? _cleanValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
