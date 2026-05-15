// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_dao.dart';

// ignore_for_file: type=lint
mixin _$BookDaoMixin on DatabaseAccessor<AppDatabase> {
  $BooksTableTable get booksTable => attachedDatabase.booksTable;
  BookDaoManager get managers => BookDaoManager(this);
}

class BookDaoManager {
  final _$BookDaoMixin _db;
  BookDaoManager(this._db);
  $$BooksTableTableTableManager get booksTable =>
      $$BooksTableTableTableManager(_db.attachedDatabase, _db.booksTable);
}
