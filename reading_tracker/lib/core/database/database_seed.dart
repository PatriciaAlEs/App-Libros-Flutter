import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';
import 'daos/book_dao.dart';

class DatabaseSeeder {
  DatabaseSeeder(this._bookDao);

  final BookDao _bookDao;
  bool _hasRun = false;

  Future<void> seedIfNeeded() async {
    if (!kDebugMode || _hasRun) return;

    _hasRun = true;

    final existingBooks = await _bookDao.getAllBooks();
    if (existingBooks.isNotEmpty) return;

    await _bookDao.insertBooks(_seedBooks());
  }

  List<BooksTableCompanion> _seedBooks() {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final oneMonthAgo = now.subtract(const Duration(days: 32));
    final fiveDaysAgo = now.subtract(const Duration(days: 5));

    // 5 pending, 5 reading, 5 completed
    return [
      // Pending
      for (var i = 1; i <= 5; i++)
        BooksTableCompanion.insert(
          id: 'seed-pending-$i',
          title: 'Pending Book $i',
          author: Value('Author P$i'),
          publisher: Value('Publisher P$i'),
          coverUrl: Value('https://picsum.photos/seed/pending$i/200/300'),
          isbn: Value('PENDING-ISBN-$i'),
          firstPublishYear: Value(2000 + i),
          totalPages: Value(150 + i * 10),
          status: const Value('pending'),
          createdAt: Value(now.subtract(Duration(days: i))),
        ),

      // Reading
      for (var i = 1; i <= 5; i++)
        BooksTableCompanion.insert(
          id: 'seed-reading-$i',
          title: 'Reading Book $i',
          author: Value('Author R$i'),
          publisher: Value('Publisher R$i'),
          coverUrl: Value('https://picsum.photos/seed/reading$i/200/300'),
          isbn: Value('READING-ISBN-$i'),
          firstPublishYear: Value(1990 + i),
          totalPages: Value(200 + i * 20),
          currentPage: Value((50 * i) % (200 + i * 20)),
          notes: Value(i == 3 ? 'Buen ritmo para leer por las tardes.' : ''),
          status: const Value('reading'),
          startDate: Value(twoWeeksAgo.subtract(Duration(days: i))),
          createdAt: Value(twoWeeksAgo.subtract(Duration(days: i))),
        ),

      // Completed
      for (var i = 1; i <= 5; i++)
        BooksTableCompanion.insert(
          id: 'seed-completed-$i',
          title: 'Completed Book $i',
          author: Value('Author C$i'),
          publisher: Value('Publisher C$i'),
          coverUrl: Value('https://picsum.photos/seed/completed$i/200/300'),
          isbn: Value('COMPLETED-ISBN-$i'),
          firstPublishYear: Value(1980 + i),
          totalPages: Value(120 + i * 15),
          currentPage: Value(0),
          rating: Value(3.5 + (i % 3)),
          notes: Value(i == 2 ? 'Lectura intensa, muy recomendable.' : ''),
          status: const Value('completed'),
          startDate: Value(oneMonthAgo.subtract(Duration(days: i * 2))),
          completedDate: Value(fiveDaysAgo.subtract(Duration(days: i))),
          createdAt: Value(oneMonthAgo.subtract(Duration(days: i * 2))),
        ),
    ];
  }
}
