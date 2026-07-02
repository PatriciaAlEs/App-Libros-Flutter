import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/backend/supabase_client_provider.dart';
import '../../domain/services/sync_debug_logger.dart';
import 'remote_sync_datasource.dart';
import 'remote_sync_tables.dart';

final remoteSyncDatasourceProvider = Provider<RemoteSyncDatasource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseRemoteSyncDatasource(client);
});

class SupabaseRemoteSyncDatasource implements RemoteSyncDatasource {
  const SupabaseRemoteSyncDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> selectOne({
    required String table,
    required String idColumn,
    required String id,
  }) async {
    final row = await _runRemote(
      table: table,
      operation: 'select_one',
      action: () => _client.from(table).select().eq(idColumn, id).maybeSingle(),
    );

    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> selectMany({
    required String table,
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    dynamic query = _client
        .from(table)
        .select()
        .eq(RemoteSyncColumns.userId, userId);

    if (updatedAfter != null) {
      query = query.gte(
        RemoteSyncColumns.updatedAt,
        updatedAfter.toUtc().toIso8601String(),
      );
    }

    if (!includeDeleted) {
      query = query.isFilter(RemoteSyncColumns.deletedAt, null);
    }

    final rows = await _runRemote(
      table: table,
      operation: 'select_many',
      userId: userId,
      action: () async => await query,
    );
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> upsertMany({
    required String table,
    required List<Map<String, dynamic>> rows,
    String? onConflict,
  }) async {
    if (rows.isEmpty) return const [];

    final response = await _runRemote(
      table: table,
      operation: 'upsert_many',
      userId: rows.first[RemoteSyncColumns.userId] as String?,
      action: () =>
          _client.from(table).upsert(rows, onConflict: onConflict).select(),
    );

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> deleteOne({
    required String table,
    required String userId,
    required String id,
  }) async {
    await _runRemote(
      table: table,
      operation: 'delete_one',
      userId: userId,
      action: () => _client
          .from(table)
          .delete()
          .eq(RemoteSyncColumns.userId, userId)
          .eq(RemoteSyncColumns.id, id),
    );
  }

  @override
  Future<void> deleteById({required String table, required String id}) async {
    await _runRemote(
      table: table,
      operation: 'delete_by_id',
      action: () => _client.from(table).delete().eq(RemoteSyncColumns.id, id),
    );
  }

  Future<T> _runRemote<T>({
    required String table,
    required String operation,
    required Future<T> Function() action,
    String? userId,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      logSyncDebugError(
        table: table,
        operation: operation,
        userId: userId,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
