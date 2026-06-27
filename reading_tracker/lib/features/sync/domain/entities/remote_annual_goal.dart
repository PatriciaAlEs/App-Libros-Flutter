class RemoteAnnualGoal {
  const RemoteAnnualGoal({
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
}
