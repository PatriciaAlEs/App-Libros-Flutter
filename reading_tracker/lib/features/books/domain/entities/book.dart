import '../enums/book_status.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.createdAt,
    this.author,
    this.totalPages,
    this.currentPage,
    this.rating,
    this.notes,
    this.publisher,
    this.coverUrl,
    this.isbn,
    this.externalSource,
    this.externalId,
    this.firstPublishYear,
    this.genre,
    this.language,
    this.status = BookStatus.pending,
    this.startDate,
    this.completedDate,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? author;
  final int? totalPages;
  final int? currentPage;
  final double? rating;
  final String? notes;
  final String? publisher;
  final String? coverUrl;
  final String? isbn;
  final String? externalSource;
  final String? externalId;
  final int? firstPublishYear;
  final String? genre;
  final String? language;
  final BookStatus status;
  final DateTime? startDate;
  final DateTime? completedDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DateTime get addedAt => createdAt;
  DateTime? get startedAt => startDate;
  DateTime? get finishedAt => completedDate;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    double? rating,
    String? notes,
    String? publisher,
    String? coverUrl,
    String? isbn,
    String? externalSource,
    String? externalId,
    int? firstPublishYear,
    String? genre,
    String? language,
    BookStatus? status,
    DateTime? startDate,
    DateTime? completedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      publisher: publisher ?? this.publisher,
      coverUrl: coverUrl ?? this.coverUrl,
      isbn: isbn ?? this.isbn,
      externalSource: externalSource ?? this.externalSource,
      externalId: externalId ?? this.externalId,
      firstPublishYear: firstPublishYear ?? this.firstPublishYear,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
