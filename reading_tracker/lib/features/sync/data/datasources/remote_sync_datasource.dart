abstract interface class RemoteSyncDatasource {
  Future<Map<String, dynamic>?> selectOne({
    required String table,
    required String idColumn,
    required String id,
  });

  Future<List<Map<String, dynamic>>> selectMany({
    required String table,
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  });

  Future<void> upsertMany({
    required String table,
    required List<Map<String, dynamic>> rows,
  });

  Future<void> deleteOne({
    required String table,
    required String userId,
    required String id,
  });
}
