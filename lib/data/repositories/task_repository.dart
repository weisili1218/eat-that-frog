import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/enums.dart';
import '../local/database.dart';
import '../local/tasks_dao.dart';
import '../remote/supabase_client.dart';

/// Local-first task repository.
///
/// Every mutation writes Drift immediately and marks the row `pendingSync`.
/// The [SyncService] (Step 10) later pushes pending rows to Supabase; this
/// class stays usable with no backend at all.
class TaskRepository {
  TaskRepository(this._dao, {this.onLocalChange});

  final TasksDao _dao;
  final _uuid = const Uuid();

  /// Fired after any local write so a sync layer can react. No-op in local mode.
  final Future<void> Function()? onLocalChange;

  String? get _userId => SupabaseService.instance.user?.id;

  Stream<List<Task>> watchAll() => _dao.watchAll();
  Future<List<Task>> getAll() => _dao.getAll();

  Future<String> add(
    String title, {
    TaskBucket bucket = TaskBucket.inbox,
    bool isFrog = false,
    String? note,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.upsert(
      TasksCompanion.insert(
        id: id,
        title: title,
        note: Value(note),
        bucket: Value(bucket),
        isFrog: Value(isFrog),
        everFrog: Value(isFrog),
        createdAt: now,
        updatedAt: now,
        userId: Value(_userId),
        pendingSync: const Value(true),
      ),
    );
    await _touch();
    return id;
  }

  Future<void> setBucket(String id, TaskBucket bucket) async {
    await _dao.updateFields(
      id,
      TasksCompanion(
        bucket: Value(bucket),
        // Leaving the today bucket clears the frog flag (matches prototype).
        isFrog: bucket == TaskBucket.today ? const Value.absent() : const Value(false),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
      ),
    );
    await _touch();
  }

  Future<void> setFrog(String id, bool value) async {
    await _dao.updateFields(
      id,
      TasksCompanion(
        isFrog: Value(value),
        everFrog: value ? const Value(true) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
      ),
    );
    await _touch();
  }

  /// Toggle completion. Pass the current row so we can flip [Task.completedAt].
  Future<void> toggleDone(Task task) async {
    final now = DateTime.now();
    await _dao.updateFields(
      task.id,
      TasksCompanion(
        completedAt: Value(task.completedAt == null ? now : null),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );
    await _touch();
  }

  Future<void> delete(String id) async {
    await _dao.softDelete(id, DateTime.now());
    await _touch();
  }

  /// Wipe everything locally (reset all data / sign-out cleanup).
  Future<void> resetAll() async {
    await _dao.clearAll();
    await _touch();
  }

  Future<void> _touch() async {
    if (onLocalChange != null) await onLocalChange!();
  }
}
