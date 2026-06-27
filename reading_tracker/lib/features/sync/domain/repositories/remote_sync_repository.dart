import '../entities/remote_annual_goal.dart';
import '../entities/remote_book.dart';
import '../entities/remote_profile.dart';
import '../entities/remote_reading_session.dart';

class RemoteSyncSnapshot {
  const RemoteSyncSnapshot({
    required this.profile,
    required this.books,
    required this.readingSessions,
    required this.annualGoals,
  });

  final RemoteProfile? profile;
  final List<RemoteBook> books;
  final List<RemoteReadingSession> readingSessions;
  final List<RemoteAnnualGoal> annualGoals;
}

abstract interface class RemoteSyncRepository {
  Future<RemoteSyncSnapshot> getSnapshot({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  });
}
