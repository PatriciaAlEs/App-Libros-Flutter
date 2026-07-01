import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../entities/remote_book.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_books_repository.dart';
import '../repositories/sync_metadata_repository.dart';

typedef LocalBookReader = Future<Book?> Function(String localId);
typedef LocalBookWriter = Future<void> Function(Book book);

class DownloadBooksResult {
  const DownloadBooksResult({
    required this.remoteBooks,
    required this.applied,
    required this.skipped,
    required this.failed,
  });

  final int remoteBooks;
  final int applied;
  final int skipped;
  final int failed;
}

class DownloadBooksFromSupabase {
  const DownloadBooksFromSupabase({
    required RemoteBooksRepository remoteBooksRepository,
    required SyncMetadataRepository metadataRepository,
    required LocalBookReader readLocalBook,
    required LocalBookWriter writeLocalBook,
  }) : _remoteBooksRepository = remoteBooksRepository,
       _metadataRepository = metadataRepository,
       _readLocalBook = readLocalBook,
       _writeLocalBook = writeLocalBook;

  final RemoteBooksRepository _remoteBooksRepository;
  final SyncMetadataRepository _metadataRepository;
  final LocalBookReader _readLocalBook;
  final LocalBookWriter _writeLocalBook;

  Future<DownloadBooksResult> call({required String userId}) async {
    final remoteBooks = await _remoteBooksRepository.getBooks(
      userId: userId,
      includeDeleted: false,
    );

    var applied = 0;
    var skipped = 0;
    var failed = 0;

    for (final remoteBook in remoteBooks) {
      if (remoteBook.deletedAt != null) {
        skipped++;
        continue;
      }

      try {
        final localId = remoteBook.localBookId;
        final metadata = await _metadataRepository.getByLocalId(
          entityType: SyncEntityType.book,
          localId: localId,
        );
        if (metadata?.hasPendingOperation ?? false) {
          skipped++;
          continue;
        }

        final existing = await _readLocalBook(localId);
        await _writeLocalBook(_bookFromRemote(remoteBook, existing: existing));
        await _metadataRepository.markSynced(
          entityType: SyncEntityType.book,
          localId: localId,
          remoteId: remoteBook.id,
          lastRemoteUpdate: remoteBook.updatedAt,
        );
        applied++;
      } catch (_) {
        failed++;
      }
    }

    return DownloadBooksResult(
      remoteBooks: remoteBooks.length,
      applied: applied,
      skipped: skipped,
      failed: failed,
    );
  }
}

Book _bookFromRemote(RemoteBook remoteBook, {Book? existing}) {
  return Book(
    id: remoteBook.localBookId,
    title: remoteBook.title,
    author: remoteBook.author,
    publisher: existing?.publisher,
    coverUrl: remoteBook.coverUrl,
    isbn: remoteBook.isbn,
    externalSource: existing?.externalSource,
    externalId: existing?.externalId,
    firstPublishYear: existing?.firstPublishYear,
    genre: existing?.genre,
    language: existing?.language,
    totalPages: remoteBook.totalPages,
    currentPage: remoteBook.currentPage,
    rating: remoteBook.rating,
    notes: existing?.notes,
    status: BookStatus.fromString(remoteBook.status),
    startDate: remoteBook.startedAt,
    completedDate: remoteBook.finishedAt,
    createdAt: remoteBook.createdAt ?? existing?.createdAt ?? DateTime.now(),
    updatedAt: remoteBook.updatedAt ?? existing?.updatedAt,
  );
}
