import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../books/data/mappers/book_mapper.dart';
import '../../../reading_sessions/data/mappers/reading_session_mapper.dart';
import '../../domain/usecases/download_reading_sessions_from_supabase.dart';
import 'remote_reading_sessions_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final downloadReadingSessionsFromSupabaseProvider =
    Provider<DownloadReadingSessionsFromSupabase?>((ref) {
      final remoteReadingSessionsRepository = ref.watch(
        remoteReadingSessionsRepositoryProvider,
      );
      if (remoteReadingSessionsRepository == null) return null;

      final database = ref.watch(databaseProvider);

      return DownloadReadingSessionsFromSupabase(
        remoteReadingSessionsRepository: remoteReadingSessionsRepository,
        metadataRepository: ref.watch(syncMetadataRepositoryProvider),
        readLocalBook: (localId) async {
          final row = await database.bookDao.getBookById(localId);
          return row?.toDomain();
        },
        readLocalSession: (localId) async {
          final row = await database.readingSessionDao.getSessionById(localId);
          return row?.toDomain();
        },
        writeLocalSession: (session) async {
          final existing = await database.readingSessionDao.getSessionById(
            session.id,
          );
          if (existing == null) {
            await database.readingSessionDao.insertSession(
              session.toCompanion(),
            );
          } else {
            await database.readingSessionDao.updateSession(
              session.toCompanion(),
            );
          }
        },
      );
    });
