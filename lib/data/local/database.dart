import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/enums.dart';
import 'tasks_dao.dart';
import 'completions_dao.dart';

part 'database.g.dart';

/// A task. Drift generates the row class `Task` and `TasksCompanion`.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get isFrog => boolean().withDefault(const Constant(false))();
  BoolColumn get everFrog => boolean().withDefault(const Constant(false))();

  /// inbox | today | later | someday (v2 uses inbox/today).
  TextColumn get bucket =>
      textEnum<TaskBucket>().withDefault(const Constant('inbox'))();

  /// easy | medium | hard.
  TextColumn get difficulty =>
      textEnum<Difficulty>().withDefault(const Constant('medium'))();

  /// Optional deadline (date only) and reminder time ('HH:mm').
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get reminderTime => text().nullable()();

  /// Estimated duration in minutes (drives the auto-planner).
  IntColumn get durationMinutes => integer().nullable()();

  /// JSON array of {id,title,done}. See [Subtask].
  TextColumn get subtasks => text().withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  TextColumn get userId => text().nullable()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per completion (frog / tadpole). Drives all stats + the streak and
/// survives day resets. Drift generates the row class `Completion`.
class Completions extends Table {
  TextColumn get id => text()();

  /// Local midnight of the day the completion happened.
  DateTimeColumn get date => dateTime()();

  /// frog | tadpole.
  TextColumn get type => textEnum<CompletionType>()();

  TextColumn get taskId => text().nullable()();

  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Tasks, Completions],
  daos: [TasksDao, CompletionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.difficulty);
            await m.addColumn(tasks, tasks.dueDate);
            await m.addColumn(tasks, tasks.reminderTime);
            await m.addColumn(tasks, tasks.subtasks);
            await m.createTable(completions);
            // Fold the removed later/someday buckets into inbox.
            await customStatement(
              "UPDATE tasks SET bucket = 'inbox' "
              "WHERE bucket IN ('later','someday')",
            );
            // daily_records is no longer used.
            await customStatement('DROP TABLE IF EXISTS daily_records');
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.durationMinutes);
          }
        },
      );

  static QueryExecutor _open() => driftDatabase(name: 'eat_that_frog');
}
