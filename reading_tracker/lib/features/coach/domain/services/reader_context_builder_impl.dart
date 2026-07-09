import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../../reading_sessions/domain/repositories/reading_session_repository.dart';
import '../../../stats/domain/repositories/annual_reading_goal_repository.dart';
import '../models/reader_context.dart';
import 'reader_context_builder.dart';

typedef ReaderProfileLoader = Future<ReaderProfile?> Function();

class ReaderContextBuilderImpl implements ReaderContextBuilder {
  const ReaderContextBuilderImpl({
    required BookRepository bookRepository,
    required ReadingSessionRepository readingSessionRepository,
    AnnualReadingGoalRepository? annualReadingGoalRepository,
    ReaderProfileLoader? readerProfileLoader,
    DateTime Function()? now,
  }) : _bookRepository = bookRepository,
       _readingSessionRepository = readingSessionRepository,
       _annualReadingGoalRepository = annualReadingGoalRepository,
       _readerProfileLoader = readerProfileLoader,
       _now = now;

  final BookRepository _bookRepository;
  final ReadingSessionRepository _readingSessionRepository;
  final AnnualReadingGoalRepository? _annualReadingGoalRepository;
  final ReaderProfileLoader? _readerProfileLoader;
  final DateTime Function()? _now;

  @override
  Future<ReaderContext> build() async {
    final generatedAt = (_now ?? DateTime.now)();
    final sessionEnd = DateTime(
      generatedAt.year,
      generatedAt.month,
      generatedAt.day,
    ).add(const Duration(days: 1));

    final books = await _bookRepository.getAllBooks();
    final sessions = await _readingSessionRepository.getSessionsInRange(
      DateTime.fromMillisecondsSinceEpoch(0),
      sessionEnd,
    );
    final annualReadingGoal = await _annualReadingGoalRepository
        ?.getAnnualReadingGoal();
    final readerProfile = await _readerProfileLoader?.call();

    return ReaderContext(
      metadata: ReaderContextMetadata(generatedAt: generatedAt),
      library: ReaderLibraryContext(
        allBooks: books,
        currentBooks: books
            .where((book) => book.status == BookStatus.reading)
            .toList(),
        completedBooks: books
            .where((book) => book.status == BookStatus.completed)
            .toList(),
        pendingBooks: books
            .where((book) => book.status == BookStatus.pending)
            .toList(),
        abandonedBooks: books
            .where((book) => book.status == BookStatus.abandoned)
            .toList(),
      ),
      activity: ReaderActivityContext(readingSessions: sessions),
      annualReadingGoal: annualReadingGoal,
      readerProfile: readerProfile,
    );
  }
}
