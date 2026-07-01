import '../../domain/entities/remote_annual_goal.dart';
import '../../domain/repositories/remote_annual_goals_repository.dart';
import '../datasources/remote_sync_datasource.dart';
import '../datasources/remote_sync_tables.dart';
import '../mappers/remote_annual_goal_mapper.dart';
import '../models/remote_annual_goal_dto.dart';

class SupabaseRemoteAnnualGoalsRepository
    implements RemoteAnnualGoalsRepository {
  const SupabaseRemoteAnnualGoalsRepository(this._datasource);

  final RemoteSyncDatasource _datasource;

  @override
  Future<List<RemoteAnnualGoal>> getAnnualGoals({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    final rows = await _datasource.selectMany(
      table: RemoteSyncTables.annualGoals,
      userId: userId,
      updatedAfter: updatedAfter,
      includeDeleted: includeDeleted,
    );

    return rows
        .map((row) => RemoteAnnualGoalDto.fromJson(row).toDomain())
        .toList();
  }

  @override
  Future<List<RemoteAnnualGoal>> upsertAnnualGoals(
    List<RemoteAnnualGoal> goals,
  ) async {
    final rows = await _datasource.upsertMany(
      table: RemoteSyncTables.annualGoals,
      rows: goals.map((goal) => goal.toDto().toJson()).toList(),
      // user_id + local_goal_id/year may use a partial unique index remotely.
      onConflict: RemoteSyncColumns.id,
    );

    return rows
        .map((row) => RemoteAnnualGoalDto.fromJson(row).toDomain())
        .toList();
  }

  @override
  Future<void> deleteAnnualGoal({
    required String userId,
    required String goalId,
  }) {
    return _datasource.deleteOne(
      table: RemoteSyncTables.annualGoals,
      userId: userId,
      id: goalId,
    );
  }
}
