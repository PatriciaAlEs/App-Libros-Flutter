import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/book_dao.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) {
    final db = AppDatabase();
    ref.onDispose(db.close);
    return db;
  },
);

final bookDaoProvider = Provider<BookDao>(
  (ref) => ref.watch(databaseProvider).bookDao,
);
