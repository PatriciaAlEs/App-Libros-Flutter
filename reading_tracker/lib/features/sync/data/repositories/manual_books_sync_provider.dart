import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../books/data/mappers/book_mapper.dart';
import '../../domain/usecases/sync_pending_books_to_supabase.dart';
import 'remote_books_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final syncPendingBooksToSupabaseProvider =
    Provider<SyncPendingBooksToSupabase?>((ref) {
      final remoteBooksRepository = ref.watch(remoteBooksRepositoryProvider);
      if (remoteBooksRepository == null) return null;

      final database = ref.watch(databaseProvider);

      return SyncPendingBooksToSupabase(
        metadataRepository: ref.watch(syncMetadataRepositoryProvider),
        remoteBooksRepository: remoteBooksRepository,
        loadBook: (localId) async {
          final row = await database.bookDao.getBookById(localId);
          return row?.toDomain();
        },
      );
    });
