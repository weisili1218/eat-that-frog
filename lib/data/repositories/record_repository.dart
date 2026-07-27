import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/records_dao.dart';
import '../remote/supabase_client.dart';

/// Streak / daily-record repository. The heavy streak recomputation lives in
/// Step 11; this provides the data access the Stats page needs now.
class RecordRepository {
  RecordRepository(this._dao, {this.onLocalChange});

  final DailyRecordsDao _dao;
  final _uuid = const Uuid();

  final Future<void> Function()? onLocalChange;

  String? get _userId => SupabaseService.instance.user?.id;

  static DateTime dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Stream<List<DailyRecord>> watchAll() => _dao.watchAll();

  Future<List<DailyRecord>> getAll() => _dao.getAll();

  Stream<List<DailyRecord>> watchLast7Days([DateTime? now]) {
    final today = dayOf(now ?? DateTime.now());
    final from = today.subtract(const Duration(days: 6));
    return _dao.watchRange(from, today);
  }

  Future<DailyRecord?> getForDay(DateTime day) => _dao.getForDate(dayOf(day));

  /// Insert or update the record for [day].
  Future<void> upsertDay({
    required DateTime day,
    required bool frogCompleted,
    required int totalCompleted,
    required int currentStreak,
  }) async {
    final existing = await _dao.getForDate(dayOf(day));
    await _dao.upsert(
      DailyRecordsCompanion(
        id: Value(existing?.id ?? _uuid.v4()),
        date: Value(dayOf(day)),
        frogCompleted: Value(frogCompleted),
        totalCompleted: Value(totalCompleted),
        currentStreak: Value(currentStreak),
        userId: Value(_userId),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
      ),
    );
    if (onLocalChange != null) await onLocalChange!();
  }

  Future<void> resetAll() async {
    await _dao.clearAll();
    if (onLocalChange != null) await onLocalChange!();
  }
}
