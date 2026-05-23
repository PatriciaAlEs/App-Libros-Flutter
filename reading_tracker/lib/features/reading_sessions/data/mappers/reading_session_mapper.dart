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
      pagesRead: Value(pagesRead),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      pagesRead: pagesRead,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
