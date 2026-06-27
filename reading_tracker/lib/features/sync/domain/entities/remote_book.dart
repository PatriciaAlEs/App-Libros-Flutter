class RemoteBook {
  const RemoteBook({
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
}
