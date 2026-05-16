import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';

extension BookDriftMapper on Book {
  BooksTableCompanion toCompanion() {
    return BooksTableCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      publisher: Value(publisher),
      coverUrl: Value(coverUrl),
      isbn: Value(isbn),
      firstPublishYear: Value(firstPublishYear),
      genre: Value(genre),
      language: Value(language),
      totalPages: Value(totalPages),
      currentPage: Value(currentPage),
      rating: Value(rating),
      notes: Value(notes),
      status: Value(status.toValue()),
      startDate: Value(startDate),
      completedDate: Value(completedDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

extension BooksTableDataMapper on BooksTableData {
  Book toDomain() {
    return Book(
      id: id,
      title: title,
      author: author,
      publisher: publisher,
      coverUrl: coverUrl,
      isbn: isbn,
      firstPublishYear: firstPublishYear,
      genre: genre,
      language: language,
      totalPages: totalPages,
      currentPage: currentPage,
      rating: rating,
      notes: notes,
      status: BookStatus.fromString(status),
      startDate: startDate,
      completedDate: completedDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
