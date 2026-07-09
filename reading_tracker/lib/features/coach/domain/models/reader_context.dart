import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/domain/entities/book.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';

class ReaderContextMetadata {
  const ReaderContextMetadata({required this.generatedAt});

  final DateTime generatedAt;
}

class ReaderLibraryContext {
  ReaderLibraryContext({
    required List<Book> allBooks,
    required List<Book> currentBooks,
    required List<Book> completedBooks,
    required List<Book> pendingBooks,
    required List<Book> abandonedBooks,
  }) : allBooks = List.unmodifiable(allBooks),
       currentBooks = List.unmodifiable(currentBooks),
       completedBooks = List.unmodifiable(completedBooks),
       pendingBooks = List.unmodifiable(pendingBooks),
       abandonedBooks = List.unmodifiable(abandonedBooks);

  final List<Book> allBooks;
  final List<Book> currentBooks;
  final List<Book> completedBooks;
  final List<Book> pendingBooks;
  final List<Book> abandonedBooks;
}

class ReaderActivityContext {
  ReaderActivityContext({required List<ReadingSession> readingSessions})
    : readingSessions = List.unmodifiable(readingSessions);

  final List<ReadingSession> readingSessions;
}

class ReaderContext {
  const ReaderContext({
    required this.metadata,
    required this.library,
    required this.activity,
    this.annualReadingGoal,
    this.readerProfile,
  });

  final ReaderContextMetadata metadata;
  final ReaderLibraryContext library;
  final ReaderActivityContext activity;
  final int? annualReadingGoal;
  final ReaderProfile? readerProfile;
}
