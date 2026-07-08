import 'package:uuid/uuid.dart';

import '../../../books/domain/entities/book.dart';
import '../entities/remote_book.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_books_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/sync_debug_logger.dart';

typedef LocalBookLoader = Future<Book?> Function(String localId);
typedef RemoteBookIdGenerator = String Function();

class SyncPendingBooksResult {
  const SyncPendingBooksResult({
    required this.pendingBooks,
    required this.synced,
    required this.failed,
    required this.ignored,
    this.failureMessages = const [],
  });

  final int pendingBooks;
  final int synced;
  final int failed;
  final int ignored;
  final List<String> failureMessages;
}

class SyncPendingBooksToSupabase {
  SyncPendingBooksToSupabase({
    required SyncMetadataRepository metadataRepository,
    required RemoteBooksRepository remoteBooksRepository,
    required LocalBookLoader loadBook,
    RemoteBookIdGenerator? remoteIdGenerator,
  }) : _metadataRepository = metadataRepository,
       _remoteBooksRepository = remoteBooksRepository,
       _loadBook = loadBook,
       _remoteIdGenerator = remoteIdGenerator ?? const Uuid().v4;

  final SyncMetadataRepository _metadataRepository;
  final RemoteBooksRepository _remoteBooksRepository;
  final LocalBookLoader _loadBook;
  final RemoteBookIdGenerator _remoteIdGenerator;

  Future<SyncPendingBooksResult> call({required String userId}) async {
    final pending = await _metadataRepository.getPendingSync();
    final pendingBooks = pending
        .where((metadata) => metadata.entityType == SyncEntityType.book)
        .toList();

    var synced = 0;
    var failed = 0;
    final failureMessages = <String>[];

    for (final metadata in pendingBooks) {
      try {
        switch (metadata.pendingOperation) {
          case PendingSyncOperation.create:
          case PendingSyncOperation.update:
            await _syncBookUpsert(metadata: metadata, userId: userId);
            synced++;
            break;
          case PendingSyncOperation.delete:
            await _syncBookDelete(metadata: metadata, userId: userId);
            synced++;
            break;
          case PendingSyncOperation.none:
            break;
        }
      } catch (error, stackTrace) {
        final message = syncFailureMessage(
          operation: metadata.pendingOperation.value,
          entityType: metadata.entityType.value,
          localId: metadata.localId,
          table: 'books',
          error: error,
        );
        failed++;
        failureMessages.add(message);
        logSyncDebugError(
          operation: metadata.pendingOperation.value,
          entityType: metadata.entityType.value,
          localId: metadata.localId,
          userId: userId,
          table: 'books',
          error: error,
          stackTrace: stackTrace,
        );
        await _metadataRepository.registerFailure(
          entityType: metadata.entityType,
          localId: metadata.localId,
          message: message,
        );
      }
    }

    return SyncPendingBooksResult(
      pendingBooks: pendingBooks.length,
      synced: synced,
      failed: failed,
      ignored: pending.length - pendingBooks.length,
      failureMessages: failureMessages,
    );
  }

  Future<void> _syncBookUpsert({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final book = await _loadBook(metadata.localId);
    if (book == null) {
      throw StateError('Local book not found: ${metadata.localId}');
    }

    final fallbackRemoteId = metadata.remoteId ?? _remoteIdGenerator();
    final remoteBook = _remoteBookFromLocal(
      book,
      userId: userId,
      remoteId: fallbackRemoteId,
    );

    final syncedBooks = await _remoteBooksRepository.upsertBooks([remoteBook]);
    final syncedBook = syncedBooks.isEmpty ? remoteBook : syncedBooks.first;

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: syncedBook.id,
      lastRemoteUpdate: syncedBook.updatedAt,
    );
  }

  Future<void> _syncBookDelete({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final remoteId = metadata.remoteId;

    if (remoteId != null) {
      await _remoteBooksRepository.deleteBook(
        userId: userId,
        remoteBookId: remoteId,
      );
    }

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: remoteId,
    );
  }
}

RemoteBook _remoteBookFromLocal(
  Book book, {
  required String userId,
  required String remoteId,
}) {
  return RemoteBook(
    id: remoteId,
    userId: userId,
    localBookId: book.id,
    title: book.title,
    author: book.author,
    isbn: book.isbn,
    coverUrl: book.coverUrl,
    totalPages: book.totalPages,
    currentPage: book.currentPage,
    status: book.status.toValue(),
    rating: book.rating,
    startedAt: book.startDate,
    finishedAt: book.completedDate,
    createdAt: book.createdAt,
    updatedAt: book.updatedAt ?? book.createdAt,
  );
}
