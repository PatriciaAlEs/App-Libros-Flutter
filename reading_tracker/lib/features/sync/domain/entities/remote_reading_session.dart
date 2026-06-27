class RemoteReadingSession {
  const RemoteReadingSession({
    required this.id,
    required this.userId,
    required this.localSessionId,
    required this.localBookId,
    required this.pagesRead,
    required this.minutesRead,
    required this.sessionDate,
    this.remoteBookId,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String localSessionId;
  final String localBookId;
  final String? remoteBookId;
  final int pagesRead;
  final int minutesRead;
  final String? note;
  final DateTime sessionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
