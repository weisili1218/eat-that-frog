import 'package:drift/drift.dart';

import 'database.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  /// All non-deleted tasks, newest first. Drives every task-facing UI stream.
  Stream<List<Task>> watchAll() {
    return (select(tasks)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<Task>> getAll() {
    return (select(tasks)..where((t) => t.deleted.equals(false))).get();
  }

  Future<Task?> getById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(TasksCompanion task) {
    return into(tasks).insertOnConflictUpdate(task);
  }

  Future<void> upsertAll(List<TasksCompanion> rows) async {
    await batch((b) {
      for (final r in rows) {
        b.insert(tasks, r, onConflict: DoUpdate((_) => r));
      }
    });
  }

  Future<void> updateFields(String id, TasksCompanion changes) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(changes);
  }

  /// Soft delete so the row can still sync as removed.
  Future<void> softDelete(String id, DateTime now) {
    return updateFields(
      id,
      TasksCompanion(
        deleted: const Value(true),
        pendingSync: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  /// Hard wipe — used by "reset all data" and on sign-out cleanup.
  Future<void> clearAll() => delete(tasks).go();

  // ---- Sync helpers (Step 10) ----

  Future<List<Task>> pendingSyncRows() {
    return (select(tasks)..where((t) => t.pendingSync.equals(true))).get();
  }

  Future<void> markSynced(String id) {
    return updateFields(id, const TasksCompanion(pendingSync: Value(false)));
  }
}
