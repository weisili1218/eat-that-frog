import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_provider.dart';
import 'local/database.dart';
import 'providers.dart';
import 'streak_service.dart';

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService(ref.watch(recordRepositoryProvider));
});

/// Drives streak recomputation on task changes, at midnight, and on resume.
/// Activated by [RootShell] watching [streakControllerProvider].
final streakControllerProvider = Provider<StreakController>((ref) {
  final c = StreakController(ref);
  c.init();
  ref.onDispose(c.dispose);
  return c;
});

class StreakController with WidgetsBindingObserver {
  StreakController(this._ref);

  final Ref _ref;
  Timer? _midnightTimer;
  ProviderSubscription<AsyncValue<List<Task>>>? _tasksSub;

  void init() {
    WidgetsBinding.instance.addObserver(this);

    // Recompute whenever the task set changes.
    _tasksSub = _ref.listen<AsyncValue<List<Task>>>(
      allTasksProvider,
      (_, next) {
        if (next.hasValue) _recompute();
      },
      fireImmediately: true,
    );

    _scheduleMidnight();
  }

  Future<void> _recompute() async {
    final tasks = _ref.read(allTasksProvider).valueOrNull ?? const [];
    final leave = _ref.read(settingsProvider).leaveEnabled;
    await _ref.read(streakServiceProvider).recompute(
          tasks: tasks,
          leaveEnabled: leave,
        );
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final wait = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(wait, () {
      _recompute();
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recompute();
      _scheduleMidnight();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _tasksSub?.close();
  }
}
