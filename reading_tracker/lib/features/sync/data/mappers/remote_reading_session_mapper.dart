import '../../domain/entities/remote_reading_session.dart';
import '../models/remote_reading_session_dto.dart';

extension RemoteReadingSessionDtoMapper on RemoteReadingSessionDto {
  RemoteReadingSession toDomain() {
    return RemoteReadingSession(
      id: id,
      userId: userId,
      localSessionId: localSessionId,
      localBookId: localBookId,
      remoteBookId: remoteBookId,
      pagesRead: pagesRead,
      minutesRead: minutesRead,
      note: note,
      sessionDate: sessionDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension RemoteReadingSessionMapper on RemoteReadingSession {
  RemoteReadingSessionDto toDto() {
    return RemoteReadingSessionDto(
      id: id,
      userId: userId,
      localSessionId: localSessionId,
      localBookId: localBookId,
      remoteBookId: remoteBookId,
      pagesRead: pagesRead,
      minutesRead: minutesRead,
      note: note,
      sessionDate: sessionDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
