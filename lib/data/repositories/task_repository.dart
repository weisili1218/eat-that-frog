import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/enums.dart';
import '../local/completions_dao.dart';
import '../local/database.dart';
import '../local/subtask.dart';
import '../local/tasks_dao.dart';
import '../remote/supabase_client.dart';

/// Local-first task repository. Also logs completions (frog/tadpole) so stats
/// and the streak survive day resets.
class TaskRepository {
  TaskRepository(this._dao, this._completions, {this.onLocalChange});

  final TasksDao _dao;
  final CompletionsDao _completions;
  final _uuid = const Uuid();

  final Future<void> Function()? onLocalChange;

  String? get _userId => SupabaseService.instance.user?.id;

  static DateTime dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Stream<List<Task>> watchAll() => _dao.watchAll();
  Future<List<Task>> getAll() => _dao.getAll();

  Future<String> add({
    required String title,
    Difficulty difficulty = Difficulty.medium,
    TaskBucket bucket = TaskBucket.inbox,
    bool isFrog = false,
    DateTime? dueDate,
    String? reminderTime,
    List<Subtask> subtasks = const [],
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.upsert(
      TasksCompanion.insert(
        id: id,
        title: title,
        bucket: Value(bucket),
        difficulty: Value(difficulty),
        isFrog: Value(isFrog),
        everFrog: Value(isFrog),
        dueDate: Value(dueDate),
        reminderTime: Value(reminderTime),
        subtasks: Value(Subtask.encode(subtasks)),
        createdAt: now,
        updatedAt: now,
        userId: Value(_userId),
        pendingSync: const Value(true),
      ),
    );
    await _touch();
    return id;
  }

  /// Edit an existing task's fields (from the composer).
  Future<void> edit(
    String id, {
    required String title,
    required Difficulty difficulty,
    DateTime? dueDate,
    String? reminderTime,
    required List<Subtask> subtasks,
  }) async {
    await _dao.updateFields(
      id,
      TasksCompanion(
        title: Value(title),
        difficulty: Value(difficulty),
        dueDate: Value(dueDate),
        reminderTime: Value(reminderTime),
        subtasks: Value(Subtask.encode(subtasks)),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
      ),
    );
    await _touch();
  }

  Future<void> setBucket(String id, TaskBucket bucket) async {
    await _dao.updateFields(
      id,
      TasksCompanion(
        bucket: Value(bucket),
        isFrog: bucket == TaskBucket.today
            ? const Value.absent()
            : const Value(false),
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

  /// Toggle completion and log/unlog the matching completion.
  Future<void> toggleDone(Task task) async {
    final now = DateTime.now();
    final willBeDone = task.completedAt == null;
    await _dao.updateFields(
      task.id,
      TasksCompanion(
        completedAt: Value(willBeDone ? now : null),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );

    final type = task.isFrog ? CompletionType.frog : CompletionType.tadpole;
    if (willBeDone) {
      await _completions.upsert(
        CompletionsCompanion.insert(
          id: _uuid.v4(),
          date: dayOf(now),
          type: type,
          taskId: Value(task.id),
          userId: Value(_userId),
          createdAt: now,
          updatedAt: now,
          pendingSync: const Value(true),
        ),
      );
    } else {
      final last = await _completions.latestForDayType(dayOf(now), type);
      if (last != null) await _completions.softDelete(last.id, now);
    }
    await _touch();
  }

  Future<void> updateSubtasks(String id, List<Subtask> subtasks) async {
    await _dao.updateFields(
      id,
      TasksCompanion(
        subtasks: Value(Subtask.encode(subtasks)),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
      ),
    );
    await _touch();
  }

  Future<void> toggleSubtask(Task task, String subtaskId) async {
    final list = Subtask.decode(task.subtasks)
        .map((s) => s.id == subtaskId ? s.copyWith(done: !s.done) : s)
        .toList();
    await updateSubtasks(task.id, list);
  }

  Future<void> delete(String id) async {
    await _dao.softDelete(id, DateTime.now());
    await _touch();
  }

  Future<void> resetAll() async {
    await _dao.clearAll();
    await _touch();
  }

  /// Dev tool: advance to "the next day" — move today's tasks back to inbox and
  /// clear their done state. Completions are kept so stats persist.
  Future<void> simulateNextDay() async {
    final all = await _dao.getAll();
    final now = DateTime.now();
    for (final t in all.where((t) => t.bucket == TaskBucket.today)) {
      await _dao.updateFields(
        t.id,
        TasksCompanion(
          bucket: const Value(TaskBucket.inbox),
          isFrog: const Value(false),
          completedAt: const Value(null),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
    }
    await _touch();
  }

  Future<void> _touch() async {
    if (onLocalChange != null) await onLocalChange!();
  }
}
