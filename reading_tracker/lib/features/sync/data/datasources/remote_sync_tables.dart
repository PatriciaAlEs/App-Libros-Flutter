class RemoteSyncTables {
  const RemoteSyncTables._();

  static const profiles = 'profiles';
  static const books = 'books';
  static const readingSessions = 'reading_sessions';
  static const annualGoals = 'annual_goals';
}

class RemoteSyncColumns {
  const RemoteSyncColumns._();

  static const id = 'id';
  static const userId = 'user_id';
  static const updatedAt = 'updated_at';
  static const deletedAt = 'deleted_at';
}
