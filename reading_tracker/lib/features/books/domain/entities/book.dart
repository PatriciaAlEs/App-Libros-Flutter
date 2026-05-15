import '../enums/book_status.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.createdAt,
    this.author,
    this.pages,
    this.status = BookStatus.pending,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String title;
  final String? author;
  final int? pages;
  final BookStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? pages,
    BookStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      pages: pages ?? this.pages,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
