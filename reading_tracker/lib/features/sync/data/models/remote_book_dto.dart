import 'remote_model_utils.dart';

class RemoteBookDto {
  const RemoteBookDto({
    required this.id,
    required this.userId,
    required this.localBookId,
    required this.title,
    required this.status,
    this.author,
    this.isbn,
    this.coverUrl,
    this.totalPages,
    this.currentPage,
    this.rating,
    this.startedAt,
    this.finishedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String localBookId;
  final String title;
  final String? author;
  final String? isbn;
  final String? coverUrl;
  final int? totalPages;
  final int? currentPage;
  final String status;
  final double? rating;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory RemoteBookDto.fromJson(Map<String, dynamic> json) {
    return RemoteBookDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      localBookId: json['local_book_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      isbn: json['isbn'] as String?,
      coverUrl: json['cover_url'] as String?,
      totalPages: json['total_pages'] as int?,
      currentPage: json['current_page'] as int?,
      status: json['status'] as String,
      rating: readDouble(json, 'rating'),
      startedAt: readDateTime(json, 'started_at'),
      finishedAt: readDateTime(json, 'finished_at'),
      createdAt: readDateTime(json, 'created_at'),
      updatedAt: readDateTime(json, 'updated_at'),
      deletedAt: readDateTime(json, 'deleted_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'local_book_id': localBookId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'cover_url': coverUrl,
      'total_pages': totalPages,
      'current_page': currentPage,
      'status': status,
      'rating': rating,
      'started_at': writeDateTime(startedAt),
      'finished_at': writeDateTime(finishedAt),
      'created_at': writeDateTime(createdAt),
      'updated_at': writeDateTime(updatedAt),
      'deleted_at': writeDateTime(deletedAt),
    };
  }
}
