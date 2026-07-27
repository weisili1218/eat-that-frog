import 'local/database.dart';
import 'local/task_x.dart';
import 'repositories/record_repository.dart';

/// Computes the streak and seals today's [DailyRecord].
///
/// Rules (per spec):
/// - Completing any frog today extends the streak.
/// - A whole day crossing midnight with no frog completed resets it to 0.
/// - With "monthly leave" on, one missed *past* day per calendar month is
///   forgiven instead of breaking the streak.
class StreakService {
  StreakService(this._records);

  final RecordRepository _records;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Recompute from [tasks] and persist today's record. Returns the streak.
  Future<int> recompute({
    required List<Task> tasks,
    required bool leaveEnabled,
    DateTime? now,
  }) async {
    final today = _day(now ?? DateTime.now());

    final frogDoneToday = tasks.any((t) => t.isFrog && t.done);
    final totalToday = tasks
        .where((t) => t.completedAt != null && _sameDay(t.completedAt!, today))
        .length;

    final records = await _records.getAll();
    bool doneOn(DateTime day) {
      if (_sameDay(day, today)) return frogDoneToday;
      for (final r in records) {
        if (_sameDay(r.date, day)) return r.frogCompleted;
      }
      return false;
    }

    // Walk backwards from today accumulating consecutive completed days.
    var streak = 0;
    final leaveUsedInMonth = <String>{};
    var cursor = today;
    var guard = 0;
    while (guard++ < 400) {
      final done = doneOn(cursor);
      if (done) {
        streak++;
        cursor = _day(cursor.subtract(const Duration(days: 1)));
        continue;
      }
      if (_sameDay(cursor, today)) {
        // Today's frog isn't done yet — don't break, count from yesterday.
        cursor = _day(cursor.subtract(const Duration(days: 1)));
        continue;
      }
      // A past day with no frog.
      final monthKey = '${cursor.year}-${cursor.month}';
      if (leaveEnabled && !leaveUsedInMonth.contains(monthKey)) {
        leaveUsedInMonth.add(monthKey); // consume this month's leave, keep going
        cursor = _day(cursor.subtract(const Duration(days: 1)));
        continue;
      }
      break; // streak is broken here
    }

    await _records.upsertDay(
      day: today,
      frogCompleted: frogDoneToday,
      totalCompleted: totalToday,
      currentStreak: streak,
    );
    return streak;
  }
}
