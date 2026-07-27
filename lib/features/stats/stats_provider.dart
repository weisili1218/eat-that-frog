import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import '../../data/providers.dart';
import '../../data/repositories/record_repository.dart';

/// One bar in the 7-day chart.
class DayBar {
  const DayBar({required this.label, required this.value, required this.isToday});
  final String label;
  final int value;
  final bool isToday;
}

/// Everything the Stats page renders.
class StatsData {
  const StatsData({
    required this.frogsEaten,
    required this.tadpolesEaten,
    required this.frogRate,
    required this.streak,
    required this.frogDoneToday,
    required this.bars,
  });

  final int frogsEaten;
  final int tadpolesEaten;
  final int frogRate;
  final int streak;
  final bool frogDoneToday;
  final List<DayBar> bars;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

final statsProvider = Provider<StatsData>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const <Task>[];
  final records = ref.watch(allRecordsProvider).valueOrNull ?? const <DailyRecord>[];
  final now = DateTime.now();
  final today = RecordRepository.dayOf(now);

  final frogsEaten = tasks.where((t) => t.isFrog && t.done).length;
  final tadpolesEaten = tasks
      .where((t) => t.isTadpole && t.done && t.bucket != TaskBucket.inbox)
      .length;
  final everFrog = tasks.where((t) => t.everFrog).length;
  final frogRate = everFrog == 0 ? 0 : ((frogsEaten / everFrog) * 100).round();

  final frogDoneToday = tasks.any((t) => t.isFrog && t.done);

  // Streak: prefer the recorded value; fall back to a live estimate.
  DailyRecord? todayRec;
  for (final r in records) {
    if (_sameDay(r.date, today)) todayRec = r;
  }
  final streak = todayRec?.currentStreak ?? (frogDoneToday ? 1 : 0);

  // Completed-per-day for the last 7 days.
  int completedToday =
      tasks.where((t) => t.completedAt != null && _sameDay(t.completedAt!, now)).length;

  final bars = <DayBar>[];
  for (var i = 6; i >= 0; i--) {
    final day = RecordRepository.dayOf(now.subtract(Duration(days: i)));
    final isToday = i == 0;
    int value;
    if (isToday) {
      value = completedToday;
    } else {
      value = records
          .where((r) => _sameDay(r.date, day))
          .fold<int>(0, (a, r) => a + r.totalCompleted);
    }
    final label = i == 0
        ? 'TODAY'
        : i == 1
            ? 'YDAY'
            : '${i}d';
    bars.add(DayBar(label: label, value: value, isToday: isToday));
  }

  return StatsData(
    frogsEaten: frogsEaten,
    tadpolesEaten: tadpolesEaten,
    frogRate: frogRate,
    streak: streak,
    frogDoneToday: frogDoneToday,
    bars: bars,
  );
});
