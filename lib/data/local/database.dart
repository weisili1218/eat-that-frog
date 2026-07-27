import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/enums.dart';
import 'tasks_dao.dart';
import 'records_dao.dart';

part 'database.g.dart';

/// A task. Drift generates the row class `Task` and `TasksCompanion`, which
/// double as the app's domain model (matching the spec's `Task` fields).
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get isFrog => boolean().withDefault(const Constant(false))();
  BoolColumn get everFrog => boolean().withDefault(const Constant(false))();

  /// Stored as the enum name: inbox | today | later | someday.
  TextColumn get bucket =>
      textEnum<TaskBucket>().withDefault(const Constant('inbox'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Owner once signed in; null in local-only mode.
  TextColumn get userId => text().nullable()();

  /// Soft-delete flag so deletions propagate through sync.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// True when local changes have not yet been pushed to Supabase.
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per calendar day. Drift generates `DailyRecord`.
class DailyRecords extends Table {
  TextColumn get id => text()();

  /// Normalized to local midnight.
  DateTimeColumn get date => dateTime()();

  BoolColumn get frogCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get totalCompleted => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();

  TextColumn get userId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {date, userId},
      ];
}

@DriftDatabase(
  tables: [Tasks, DailyRecords],
  daos: [TasksDao, DailyRecordsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// For unit tests: `AppDatabase.forTesting(NativeDatabase.memory())`.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() => driftDatabase(name: 'eat_that_frog');
}
