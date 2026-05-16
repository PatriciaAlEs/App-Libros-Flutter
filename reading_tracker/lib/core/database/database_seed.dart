import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

class DatabaseSeeder {
  DatabaseSeeder(this._database);

  final AppDatabase _database;
  bool _hasRun = false;

  Future<void> seedIfNeeded() async {
    if (!kDebugMode || _hasRun) return;

    _hasRun = true;

    final existingBooks = await _database.bookDao.getAllBooks();
    if (existingBooks.isNotEmpty) return;

    await _database.bookDao.insertBooks(_seedBooks());
    await _database.readingSessionDao.insertSessions(_seedSessions());
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

  List<ReadingSessionsTableCompanion> _seedSessions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      _session('seed-session-1', 'seed-earthsea', today, 35),
      _session(
        'seed-session-2',
        'seed-earthsea',
        today.subtract(const Duration(days: 1)),
        45,
      ),
      _session(
        'seed-session-3',
        'seed-left-hand-darkness',
        today.subtract(const Duration(days: 2)),
        60,
      ),
      _session(
        'seed-session-4',
        'seed-dune',
        today.subtract(const Duration(days: 3)),
        25,
      ),
      _session(
        'seed-session-5',
        'seed-earthsea',
        today.subtract(const Duration(days: 3)),
        30,
      ),
      _session(
        'seed-session-6',
        'seed-left-hand-darkness',
        today.subtract(const Duration(days: 5)),
        50,
      ),
    ];
  }

  ReadingSessionsTableCompanion _session(
    String id,
    String bookId,
    DateTime date,
    int minutes,
  ) {
    return ReadingSessionsTableCompanion.insert(
      id: id,
      bookId: bookId,
      date: date,
      minutes: minutes,
      note: const Value('Sesion de prueba'),
      createdAt: Value(date),
    );
  }
}
