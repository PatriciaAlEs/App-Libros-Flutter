enum AccountMigrationPreparationStatus {
  unauthenticated,
  noLocalData,
  readyForFutureSync,
}

enum AccountMigrationDataScope {
  library,
  readingProgress,
  readingSessions,
  statistics,
  preferences,
}

class AccountMigrationLocalDataSummary {
  const AccountMigrationLocalDataSummary({
    required this.bookCount,
    required this.readingSessionCount,
    required this.hasAnnualGoal,
    required this.hasReaderProfile,
  });

  final int bookCount;
  final int readingSessionCount;
  final bool hasAnnualGoal;
  final bool hasReaderProfile;

  bool get hasLibrary => bookCount > 0;
  bool get hasReadingSessions => readingSessionCount > 0;
  bool get hasStatistics => hasAnnualGoal;
  bool get hasPreferences => hasReaderProfile;

  bool get hasLocalData =>
      hasLibrary || hasReadingSessions || hasStatistics || hasPreferences;

  List<AccountMigrationDataScope> get scopes {
    return [
      if (hasLibrary) AccountMigrationDataScope.library,
      if (hasLibrary) AccountMigrationDataScope.readingProgress,
      if (hasReadingSessions) AccountMigrationDataScope.readingSessions,
      if (hasStatistics) AccountMigrationDataScope.statistics,
      if (hasPreferences) AccountMigrationDataScope.preferences,
    ];
  }
}

class AccountMigrationPreparation {
  const AccountMigrationPreparation({
    required this.status,
    required this.summary,
    this.userId,
  });

  final AccountMigrationPreparationStatus status;
  final String? userId;
  final AccountMigrationLocalDataSummary summary;

  bool get isReadyForFutureSync =>
      status == AccountMigrationPreparationStatus.readyForFutureSync;
}
