import 'package:drift/drift.dart';

class SyncMetadataTable extends Table {
  @override
  String get tableName => 'sync_metadata';

  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get localId => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get syncStatus => text()();
  TextColumn get pendingOperation => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get lastLocalUpdate => dateTime().nullable()();
  DateTimeColumn get lastRemoteUpdate => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE(entity_type, local_id)'];
}
