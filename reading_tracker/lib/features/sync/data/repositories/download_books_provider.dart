import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../books/data/mappers/book_mapper.dart';
import '../../domain/usecases/download_books_from_supabase.dart';
import 'remote_books_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final downloadBooksFromSupabaseProvider = Provider<DownloadBooksFromSupabase?>((
  ref,
) {
  final remoteBooksRepository = ref.watch(remoteBooksRepositoryProvider);
  if (remoteBooksRepository == null) return null;

  final database = ref.watch(databaseProvider);

  return DownloadBooksFromSupabase(
    remoteBooksRepository: remoteBooksRepository,
    metadataRepository: ref.watch(syncMetadataRepositoryProvider),
    readLocalBook: (localId) async {
      final row = await database.bookDao.getBookById(localId);
      return row?.toDomain();
    },
    writeLocalBook: (book) {
      return database.bookDao.upsertBooks([book.toCompanion()]);
    },
  );
});
