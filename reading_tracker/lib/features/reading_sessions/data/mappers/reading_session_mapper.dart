import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/reading_session.dart';

extension ReadingSessionDriftMapper on ReadingSession {
  ReadingSessionsTableCompanion toCompanion() {
    return ReadingSessionsTableCompanion(
      id: Value(id),
      bookId: Value(bookId),
      date: Value(DateTime(date.year, date.month, date.day)),
      minutes: Value(minutes),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }
}

extension ReadingSessionsTableDataMapper on ReadingSessionsTableData {
  ReadingSession toDomain() {
    return ReadingSession(
      id: id,
      bookId: bookId,
      date: date,
      minutes: minutes,
      note: note,
      createdAt: createdAt,
    );
  }
}
