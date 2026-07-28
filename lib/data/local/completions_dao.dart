import 'package:drift/drift.dart';

import '../../core/enums.dart';
import 'database.dart';

part 'completions_dao.g.dart';

@DriftAccessor(tables: [Completions])
class CompletionsDao extends DatabaseAccessor<AppDatabase>
    with _$CompletionsDaoMixin {
  CompletionsDao(super.db);

  Stream<List<Completion>> watchAll() {
    return (select(completions)..where((c) => c.deleted.equals(false)))
        .watch();
  }

  Future<List<Completion>> getAll() {
    return (select(completions)..where((c) => c.deleted.equals(false))).get();
  }

  Future<void> upsert(CompletionsCompanion c) {
    return into(completions).insertOnConflictUpdate(c);
  }

  Future<void> upsertAll(List<CompletionsCompanion> rows) async {
    await batch((b) {
      for (final r in rows) {
        b.insert(completions, r, onConflict: DoUpdate((_) => r));
      }
    });
  }

  /// Most recent non-deleted completion of [type] on [dayMidnight].
  Future<Completion?> latestForDayType(
    DateTime dayMidnight,
    CompletionType type,
  ) {
    return (select(completions)
          ..where((c) =>
              c.deleted.equals(false) &
              c.date.equals(dayMidnight) &
              c.type.equalsValue(type))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> softDelete(String id, DateTime now) {
    return (update(completions)..where((c) => c.id.equals(id))).write(
      CompletionsCompanion(
        deleted: const Value(true),
        pendingSync: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> clearAll() => delete(completions).go();

  // ---- sync ----
  Future<List<Completion>> pendingSyncRows() {
    return (select(completions)..where((c) => c.pendingSync.equals(true))).get();
  }

  Future<void> markSynced(String id) {
    return (update(completions)..where((c) => c.id.equals(id)))
        .write(const CompletionsCompanion(pendingSync: Value(false)));
  }
}
