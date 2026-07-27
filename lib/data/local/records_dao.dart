import 'package:drift/drift.dart';

import 'database.dart';

part 'records_dao.g.dart';

@DriftAccessor(tables: [DailyRecords])
class DailyRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyRecordsDaoMixin {
  DailyRecordsDao(super.db);

  Stream<List<DailyRecord>> watchAll() {
    return (select(dailyRecords)
          ..orderBy([(r) => OrderingTerm.asc(r.date)]))
        .watch();
  }

  Future<List<DailyRecord>> getAll() {
    return (select(dailyRecords)
          ..orderBy([(r) => OrderingTerm.asc(r.date)]))
        .get();
  }

  /// Records within [from, to] inclusive — used for the 7-day chart.
  Stream<List<DailyRecord>> watchRange(DateTime from, DateTime to) {
    return (select(dailyRecords)
          ..where((r) => r.date.isBetweenValues(from, to))
          ..orderBy([(r) => OrderingTerm.asc(r.date)]))
        .watch();
  }

  Future<DailyRecord?> getForDate(DateTime dayMidnight) {
    return (select(dailyRecords)..where((r) => r.date.equals(dayMidnight)))
        .getSingleOrNull();
  }

  Future<void> upsert(DailyRecordsCompanion record) {
    return into(dailyRecords).insertOnConflictUpdate(record);
  }

  Future<void> upsertAll(List<DailyRecordsCompanion> rows) async {
    await batch((b) {
      for (final r in rows) {
        b.insert(dailyRecords, r, onConflict: DoUpdate((_) => r));
      }
    });
  }

  Future<void> clearAll() => delete(dailyRecords).go();

  // ---- Sync helpers (Step 10) ----

  Future<List<DailyRecord>> pendingSyncRows() {
    return (select(dailyRecords)..where((r) => r.pendingSync.equals(true)))
        .get();
  }

  Future<void> markSynced(String id) {
    return (update(dailyRecords)..where((r) => r.id.equals(id)))
        .write(const DailyRecordsCompanion(pendingSync: Value(false)));
  }
}
