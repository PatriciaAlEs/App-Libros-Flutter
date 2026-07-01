import '../../domain/entities/remote_profile.dart';
import '../../domain/repositories/remote_profile_repository.dart';
import '../datasources/remote_sync_datasource.dart';
import '../datasources/remote_sync_tables.dart';
import '../mappers/remote_profile_mapper.dart';
import '../models/remote_profile_dto.dart';

class SupabaseRemoteProfileRepository implements RemoteProfileRepository {
  const SupabaseRemoteProfileRepository(this._datasource);

  final RemoteSyncDatasource _datasource;

  @override
  Future<RemoteProfile?> getProfile(String userId) async {
    final row = await _datasource.selectOne(
      table: RemoteSyncTables.profiles,
      idColumn: RemoteSyncColumns.id,
      id: userId,
    );

    return row == null ? null : RemoteProfileDto.fromJson(row).toDomain();
  }

  @override
  Future<RemoteProfile> upsertProfile(RemoteProfile profile) async {
    final rows = await _datasource.upsertMany(
      table: RemoteSyncTables.profiles,
      rows: [profile.toDto().toJson()],
      onConflict: RemoteSyncColumns.id,
    );

    return rows.isEmpty
        ? profile
        : RemoteProfileDto.fromJson(rows.first).toDomain();
  }

  @override
  Future<void> deleteProfile(String userId) {
    return _datasource.deleteById(table: RemoteSyncTables.profiles, id: userId);
  }
}
