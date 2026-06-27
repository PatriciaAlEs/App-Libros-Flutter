import 'remote_model_utils.dart';

class RemoteAnnualGoalDto {
  const RemoteAnnualGoalDto({
    required this.id,
    required this.userId,
    required this.year,
    required this.targetBooks,
    this.localGoalId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String? localGoalId;
  final int year;
  final int targetBooks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory RemoteAnnualGoalDto.fromJson(Map<String, dynamic> json) {
    return RemoteAnnualGoalDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      localGoalId: json['local_goal_id'] as String?,
      year: json['year'] as int,
      targetBooks: json['target_books'] as int,
      createdAt: readDateTime(json, 'created_at'),
      updatedAt: readDateTime(json, 'updated_at'),
      deletedAt: readDateTime(json, 'deleted_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'local_goal_id': localGoalId,
      'year': year,
      'target_books': targetBooks,
      'created_at': writeDateTime(createdAt),
      'updated_at': writeDateTime(updatedAt),
      'deleted_at': writeDateTime(deletedAt),
    };
  }
}
