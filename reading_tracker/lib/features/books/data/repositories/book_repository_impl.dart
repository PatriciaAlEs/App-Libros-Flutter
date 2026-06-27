import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/book_dao.dart';
import '../../../../core/database/database_seed.dart';
import '../../../sync/domain/services/local_sync_tracker.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../mappers/book_mapper.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(AppDatabase database, {LocalSyncTracker? syncTracker})
    : _dao = database.bookDao,
      _seeder = DatabaseSeeder(database),
      _syncTracker = syncTracker;

  final BookDao _dao;
  final DatabaseSeeder _seeder;
  final LocalSyncTracker? _syncTracker;

  @override
  Future<void> addBook(Book book) async {
    await _seeder.seedIfNeeded();
    await _dao.insertBook(book.toCompanion());
    await _syncTracker?.trackBookCreated(book.id);
  }

  @override
  Future<List<Book>> getAllBooks() async {
    await _seeder.seedIfNeeded();
    final rows = await _dao.getAllBooks();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Stream<List<Book>> watchBooks() {
    return Stream.fromFuture(_seeder.seedIfNeeded()).asyncExpand(
      (_) => _dao.watchAllBooks().map(
        (rows) => rows.map((row) => row.toDomain()).toList(),
      ),
    );
  }

  @override
  Future<Book?> getBookById(String id) async {
    await _seeder.seedIfNeeded();
    final row = await _dao.getBookById(id);
    return row?.toDomain();
  }

  @override
  Future<void> updateBook(Book book) async {
    await _seeder.seedIfNeeded();
    await _dao.updateBook(book.toCompanion());
    await _syncTracker?.trackBookUpdated(book.id);
  }

  @override
  Future<void> deleteBook(String id) async {
    await _seeder.seedIfNeeded();
    await _dao.deleteBook(id);
    await _syncTracker?.trackBookDeleted(id);
  }
}
