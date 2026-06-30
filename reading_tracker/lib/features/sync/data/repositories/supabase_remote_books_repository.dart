import '../../domain/entities/remote_book.dart';
import '../../domain/repositories/remote_books_repository.dart';
import '../datasources/remote_sync_datasource.dart';
import '../datasources/remote_sync_tables.dart';
import '../mappers/remote_book_mapper.dart';
import '../models/remote_book_dto.dart';

class SupabaseRemoteBooksRepository implements RemoteBooksRepository {
  const SupabaseRemoteBooksRepository(this._datasource);

  final RemoteSyncDatasource _datasource;

  @override
  Future<List<RemoteBook>> getBooks({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    final rows = await _datasource.selectMany(
      table: RemoteSyncTables.books,
      userId: userId,
      updatedAfter: updatedAfter,
      includeDeleted: includeDeleted,
    );

    return rows.map((row) => RemoteBookDto.fromJson(row).toDomain()).toList();
  }

  @override
  Future<List<RemoteBook>> upsertBooks(List<RemoteBook> books) async {
    final rows = await _datasource.upsertMany(
      table: RemoteSyncTables.books,
      rows: books.map((book) => book.toDto().toJson()).toList(),
      onConflict: RemoteSyncColumns.id,
    );

    return rows.map((row) => RemoteBookDto.fromJson(row).toDomain()).toList();
  }

  @override
  Future<void> deleteBook({
    required String userId,
    required String remoteBookId,
  }) {
    return _datasource.deleteOne(
      table: RemoteSyncTables.books,
      userId: userId,
      id: remoteBookId,
    );
  }
}
