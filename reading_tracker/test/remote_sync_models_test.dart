import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/sync/data/mappers/remote_annual_goal_mapper.dart';
import 'package:reading_tracker/features/sync/data/mappers/remote_book_mapper.dart';
import 'package:reading_tracker/features/sync/data/mappers/remote_profile_mapper.dart';
import 'package:reading_tracker/features/sync/data/mappers/remote_reading_session_mapper.dart';
import 'package:reading_tracker/features/sync/data/models/remote_annual_goal_dto.dart';
import 'package:reading_tracker/features/sync/data/models/remote_book_dto.dart';
import 'package:reading_tracker/features/sync/data/models/remote_profile_dto.dart';
import 'package:reading_tracker/features/sync/data/models/remote_reading_session_dto.dart';

void main() {
  test('remote profile dto maps audit columns', () {
    final dto = RemoteProfileDto.fromJson({
      'id': 'user-1',
      'reader_name': 'Patricia',
      'greeting': 'female',
      'custom_greeting': null,
      'created_at': '2026-06-27T10:00:00Z',
      'updated_at': '2026-06-27T10:30:00Z',
      'deleted_at': null,
    });

    final profile = dto.toDomain();
    final json = profile.toDto().toJson();

    expect(profile.id, 'user-1');
    expect(profile.readerName, 'Patricia');
    expect(json['reader_name'], 'Patricia');
    expect(json['created_at'], '2026-06-27T10:00:00.000Z');
    expect(json['updated_at'], '2026-06-27T10:30:00.000Z');
    expect(json, containsPair('deleted_at', null));
  });

  test('remote book dto keeps remote and local identifiers', () {
    final dto = RemoteBookDto.fromJson({
      'id': 'remote-book-1',
      'user_id': 'user-1',
      'local_book_id': 'local-book-1',
      'title': 'Book',
      'author': 'Author',
      'isbn': '123',
      'cover_url': 'https://example.com/cover.jpg',
      'total_pages': 320,
      'current_page': 120,
      'status': 'reading',
      'rating': 4.5,
      'started_at': '2026-06-01T00:00:00Z',
      'finished_at': null,
      'created_at': '2026-06-27T10:00:00Z',
      'updated_at': '2026-06-27T10:30:00Z',
      'deleted_at': null,
    });

    final book = dto.toDomain();
    final json = book.toDto().toJson();

    expect(book.id, 'remote-book-1');
    expect(book.localBookId, 'local-book-1');
    expect(json['user_id'], 'user-1');
    expect(json['local_book_id'], 'local-book-1');
    expect(json['status'], 'reading');
  });

  test('remote reading session dto serializes session date as date', () {
    final dto = RemoteReadingSessionDto.fromJson({
      'id': 'remote-session-1',
      'user_id': 'user-1',
      'local_session_id': 'local-session-1',
      'local_book_id': 'local-book-1',
      'remote_book_id': 'remote-book-1',
      'pages_read': 24,
      'minutes_read': 30,
      'note': 'Nice chapter',
      'session_date': '2026-06-27',
      'created_at': '2026-06-27T10:00:00Z',
      'updated_at': '2026-06-27T10:30:00Z',
      'deleted_at': null,
    });

    final session = dto.toDomain();
    final json = session.toDto().toJson();

    expect(session.localSessionId, 'local-session-1');
    expect(session.remoteBookId, 'remote-book-1');
    expect(json['session_date'], '2026-06-27');
    expect(json['minutes_read'], 30);
  });

  test('remote annual goal dto keeps yearly target', () {
    final dto = RemoteAnnualGoalDto.fromJson({
      'id': 'goal-1',
      'user_id': 'user-1',
      'local_goal_id': 'annualReadingGoal',
      'year': 2026,
      'target_books': 24,
      'created_at': '2026-06-27T10:00:00Z',
      'updated_at': '2026-06-27T10:30:00Z',
      'deleted_at': null,
    });

    final goal = dto.toDomain();
    final json = goal.toDto().toJson();

    expect(goal.year, 2026);
    expect(goal.targetBooks, 24);
    expect(json['local_goal_id'], 'annualReadingGoal');
    expect(json['target_books'], 24);
  });
}
