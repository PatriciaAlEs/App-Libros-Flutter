import 'package:drift/drift.dart';
import 'package:reading_tracker/core/database/app_database.dart';
import 'package:reading_tracker/features/stats/domain/repositories/annual_reading_goal_repository.dart';

class DriftAnnualReadingGoalRepository implements AnnualReadingGoalRepository {
  const DriftAnnualReadingGoalRepository(this._database);

  static const _goalKey = 'annualReadingGoal';

  final AppDatabase _database;

  @override
  Future<int?> getAnnualReadingGoal() async {
    final row = await _database
        .customSelect(
          'SELECT int_value FROM app_settings WHERE key = ? LIMIT 1',
          variables: [Variable<String>(_goalKey)],
        )
        .getSingleOrNull();

    return row?.read<int?>('int_value');
  }

  @override
  Future<void> saveAnnualReadingGoal(int goal) {
    return _database.customStatement(
      '''
      INSERT INTO app_settings (key, int_value, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(key) DO UPDATE SET
        int_value = excluded.int_value,
        updated_at = excluded.updated_at
      ''',
      [_goalKey, goal, DateTime.now().millisecondsSinceEpoch],
    );
  }
}
