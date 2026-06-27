import 'remote_model_utils.dart';

class RemoteReadingSessionDto {
  const RemoteReadingSessionDto({
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

  factory RemoteReadingSessionDto.fromJson(Map<String, dynamic> json) {
    return RemoteReadingSessionDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      localSessionId: json['local_session_id'] as String,
      localBookId: json['local_book_id'] as String,
      remoteBookId: json['remote_book_id'] as String?,
      pagesRead: json['pages_read'] as int? ?? 0,
      minutesRead: json['minutes_read'] as int? ?? 0,
      note: json['note'] as String?,
      sessionDate: readRequiredDate(json, 'session_date'),
      createdAt: readDateTime(json, 'created_at'),
      updatedAt: readDateTime(json, 'updated_at'),
      deletedAt: readDateTime(json, 'deleted_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'local_session_id': localSessionId,
      'local_book_id': localBookId,
      'remote_book_id': remoteBookId,
      'pages_read': pagesRead,
      'minutes_read': minutesRead,
      'note': note,
      'session_date': writeDate(sessionDate),
      'created_at': writeDateTime(createdAt),
      'updated_at': writeDateTime(updatedAt),
      'deleted_at': writeDateTime(deletedAt),
    };
  }
}
