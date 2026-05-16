import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/book_dao.dart';
import 'daos/reading_session_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final bookDaoProvider = Provider<BookDao>(
  (ref) => ref.watch(databaseProvider).bookDao,
);

final readingSessionDaoProvider = Provider<ReadingSessionDao>(
  (ref) => ref.watch(databaseProvider).readingSessionDao,
);
