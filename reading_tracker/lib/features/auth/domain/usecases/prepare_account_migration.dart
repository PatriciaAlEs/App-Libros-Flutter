import '../../../books/domain/repositories/book_repository.dart';
import '../../../reading_sessions/domain/repositories/reading_session_repository.dart';
import '../../../stats/domain/repositories/annual_reading_goal_repository.dart';
import '../app_user.dart';
import '../entities/account_migration_preparation.dart';

class PrepareAccountMigration {
  const PrepareAccountMigration({
    required BookRepository bookRepository,
    required ReadingSessionRepository readingSessionRepository,
    required AnnualReadingGoalRepository annualReadingGoalRepository,
  }) : _bookRepository = bookRepository,
       _readingSessionRepository = readingSessionRepository,
       _annualReadingGoalRepository = annualReadingGoalRepository;

  final BookRepository _bookRepository;
  final ReadingSessionRepository _readingSessionRepository;
  final AnnualReadingGoalRepository _annualReadingGoalRepository;

  Future<AccountMigrationPreparation> call({
    required AppUser? user,
    required bool hasReaderProfileData,
  }) async {
    if (user == null) {
      return const AccountMigrationPreparation(
        status: AccountMigrationPreparationStatus.unauthenticated,
        summary: AccountMigrationLocalDataSummary(
          bookCount: 0,
          readingSessionCount: 0,
          hasAnnualGoal: false,
          hasReaderProfile: false,
        ),
      );
    }

    final books = await _bookRepository.getAllBooks();
    final sessionsByBook = await Future.wait(
      books.map(
        (book) => _readingSessionRepository.getSessionsForBook(book.id),
      ),
    );
    final annualGoal = await _annualReadingGoalRepository
        .getAnnualReadingGoal();
    final summary = AccountMigrationLocalDataSummary(
      bookCount: books.length,
      readingSessionCount: sessionsByBook.fold<int>(
        0,
        (total, sessions) => total + sessions.length,
      ),
      hasAnnualGoal: annualGoal != null && annualGoal > 0,
      hasReaderProfile: hasReaderProfileData,
    );

    return AccountMigrationPreparation(
      status: summary.hasLocalData
          ? AccountMigrationPreparationStatus.readyForFutureSync
          : AccountMigrationPreparationStatus.noLocalData,
      userId: user.id,
      summary: summary,
    );
  }
}
