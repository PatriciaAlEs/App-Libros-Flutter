import '../../domain/entities/remote_annual_goal.dart';
import '../models/remote_annual_goal_dto.dart';

extension RemoteAnnualGoalDtoMapper on RemoteAnnualGoalDto {
  RemoteAnnualGoal toDomain() {
    return RemoteAnnualGoal(
      id: id,
      userId: userId,
      localGoalId: localGoalId,
      year: year,
      targetBooks: targetBooks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension RemoteAnnualGoalMapper on RemoteAnnualGoal {
  RemoteAnnualGoalDto toDto() {
    return RemoteAnnualGoalDto(
      id: id,
      userId: userId,
      localGoalId: localGoalId,
      year: year,
      targetBooks: targetBooks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
