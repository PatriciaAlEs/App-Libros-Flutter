import '../../domain/entities/remote_profile.dart';
import '../models/remote_profile_dto.dart';

extension RemoteProfileDtoMapper on RemoteProfileDto {
  RemoteProfile toDomain() {
    return RemoteProfile(
      id: id,
      readerName: readerName,
      greeting: greeting,
      customGreeting: customGreeting,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension RemoteProfileMapper on RemoteProfile {
  RemoteProfileDto toDto() {
    return RemoteProfileDto(
      id: id,
      readerName: readerName,
      greeting: greeting,
      customGreeting: customGreeting,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
