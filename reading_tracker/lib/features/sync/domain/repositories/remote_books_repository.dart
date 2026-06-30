import '../entities/remote_book.dart';

abstract interface class RemoteBooksRepository {
  Future<List<RemoteBook>> getBooks({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  });

  Future<List<RemoteBook>> upsertBooks(List<RemoteBook> books);

  Future<void> deleteBook({
    required String userId,
    required String remoteBookId,
  });
}
