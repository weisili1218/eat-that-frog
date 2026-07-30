import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../settings/settings_provider.dart';
import 'freeze_controller.dart';

class DayBar {
  const DayBar({
    required this.label,
    required this.value,
    required this.frogValue,
    required this.tadpoleValue,
    required this.isToday,
  });
  final String label;
  final int value;
  final int frogValue;
  final int tadpoleValue;
  final bool isToday;
}

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

DateTime _day(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// All stats derive from the completions log + tasks (for frog-rate denominator).
final statsProvider = Provider<StatsData>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const <Task>[];
  final completions =
      ref.watch(allCompletionsProvider).valueOrNull ?? const <Completion>[];
  final leaveEnabled = ref.watch(settingsProvider).leaveEnabled;
  final frozenDays = ref.watch(freezeControllerProvider).usedDays;

  final now = DateTime.now();
  final today = _day(now);

  final frogsEaten =
      completions.where((c) => c.type == CompletionType.frog).length;
  final tadpolesEaten =
      completions.where((c) => c.type == CompletionType.tadpole).length;

  final everFrog = tasks.where((t) => t.everFrog).length;
  final denom = everFrog == 0 ? 0 : (everFrog > frogsEaten ? everFrog : frogsEaten);
  final frogRate = denom == 0 ? 0 : ((frogsEaten / denom) * 100).round();

  bool frogOn(DateTime day) =>
      frozenDays.contains(freezeDayKey(day)) ||
      completions.any((c) => c.type == CompletionType.frog && _sameDay(c.date, day));
  final frogDoneToday =
      completions.any((c) => c.type == CompletionType.frog && _sameDay(c.date, today));

  // Streak: consecutive days (ending today or yesterday) with a frog, with an
  // optional single "leave" day forgiven per calendar month.
  var streak = 0;
  final leaveUsed = <String>{};
  var cursor = today;
  var guard = 0;
  while (guard++ < 400) {
    if (frogOn(cursor)) {
      streak++;
      cursor = _day(cursor.subtract(const Duration(days: 1)));
      continue;
    }
    if (_sameDay(cursor, today)) {
      cursor = _day(cursor.subtract(const Duration(days: 1)));
      continue; // today not done yet — don't break
    }
    final monthKey = '${cursor.year}-${cursor.month}';
    if (leaveEnabled && !leaveUsed.contains(monthKey)) {
      leaveUsed.add(monthKey);
      cursor = _day(cursor.subtract(const Duration(days: 1)));
      continue;
    }
    break;
  }

  final bars = <DayBar>[];
  for (var i = 6; i >= 0; i--) {
    final day = _day(now.subtract(Duration(days: i)));
    final dayCompletions = completions.where((c) => _sameDay(c.date, day));
    final frogValue =
        dayCompletions.where((c) => c.type == CompletionType.frog).length;
    final tadpoleValue =
        dayCompletions.where((c) => c.type == CompletionType.tadpole).length;
    final label = i == 0 ? 'TODAY' : (i == 1 ? 'YDAY' : '${i}d');
    bars.add(DayBar(
      label: label,
      value: frogValue + tadpoleValue,
      frogValue: frogValue,
      tadpoleValue: tadpoleValue,
      isToday: i == 0,
    ));
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
