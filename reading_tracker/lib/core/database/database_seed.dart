import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

class DatabaseSeeder {
  DatabaseSeeder(this._database);

  final AppDatabase _database;
  bool _hasRun = false;

  static const bool enableDemoLibrary = false;

  Future<void> seedIfNeeded() async {
    if (_hasRun) return;

    _hasRun = true;
    await _database.readingSessionDao.deleteLegacySeedSessions();
    await _database.bookDao.deleteLegacySeedBooks();

    if (!kDebugMode || !enableDemoLibrary) return;

    final existingBooks = await _database.bookDao.getAllBooks();
    if (existingBooks.isNotEmpty) return;

    await _database.bookDao.insertBooks(_seedBooks());
  }

  List<BooksTableCompanion> _seedBooks() {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final oneMonthAgo = now.subtract(const Duration(days: 32));
    final fiveDaysAgo = now.subtract(const Duration(days: 5));

    return [
      BooksTableCompanion.insert(
        id: 'seed-dune',
        title: 'Dune',
        author: const Value('Frank Herbert'),
        publisher: const Value('Ace'),
        coverUrl: const Value(
          'https://covers.openlibrary.org/b/id/14824735-M.jpg',
        ),
        isbn: const Value('9780441172719'),
        firstPublishYear: const Value(1965),
        genre: const Value('Science fiction'),
        language: const Value('English'),
        totalPages: const Value(688),
        status: const Value('pending'),
        createdAt: Value(now.subtract(const Duration(days: 2))),
      ),
      BooksTableCompanion.insert(
        id: 'seed-earthsea',
        title: 'A Wizard of Earthsea',
        author: const Value('Ursula K. Le Guin'),
        publisher: const Value('Parnassus Press'),
        coverUrl: const Value(
          'https://covers.openlibrary.org/b/id/8231856-M.jpg',
        ),
        isbn: const Value('9780547773742'),
        firstPublishYear: const Value(1968),
        genre: const Value('Fantasy'),
        language: const Value('English'),
        totalPages: const Value(205),
        currentPage: const Value(86),
        notes: const Value('Buen ritmo para leer por las tardes.'),
        status: const Value('reading'),
        startDate: Value(twoWeeksAgo),
        createdAt: Value(twoWeeksAgo),
      ),
      BooksTableCompanion.insert(
        id: 'seed-left-hand-darkness',
        title: 'The Left Hand of Darkness',
        author: const Value('Ursula K. Le Guin'),
        publisher: const Value('Ace Books'),
        coverUrl: const Value(
          'https://covers.openlibrary.org/b/id/9255566-M.jpg',
        ),
        isbn: const Value('9780441478125'),
        firstPublishYear: const Value(1969),
        genre: const Value('Science fiction'),
        language: const Value('English'),
        totalPages: const Value(304),
        currentPage: const Value(304),
        rating: const Value(4.5),
        notes: const Value('Lectura intensa, muy recomendable.'),
        status: const Value('completed'),
        startDate: Value(oneMonthAgo),
        completedDate: Value(fiveDaysAgo),
        createdAt: Value(oneMonthAgo),
      ),
    ];
  }
}
