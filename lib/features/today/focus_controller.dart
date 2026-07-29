import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live focus-session state. [elapsed] is computed from the clock so the UI can
/// tick every second.
@immutable
class FocusState {
  const FocusState({
    this.taskId,
    this.startedAt,
    this.paused = false,
    this.pausedAccumMs = 0,
    this.pausedAt,
    this.todayMinutes = 0,
  });

  final String? taskId;
  final DateTime? startedAt;
  final bool paused;
  final int pausedAccumMs;
  final DateTime? pausedAt;

  /// Total focused minutes logged today (persisted), excludes the live session.
  final int todayMinutes;

  bool get active => taskId != null;

  Duration get elapsed {
    if (startedAt == null) return Duration.zero;
    final now = DateTime.now();
    var ms = now.difference(startedAt!).inMilliseconds - pausedAccumMs;
    if (paused && pausedAt != null) ms -= now.difference(pausedAt!).inMilliseconds;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  FocusState copyWith({
    Object? taskId = _keep,
    Object? startedAt = _keep,
    bool? paused,
    int? pausedAccumMs,
    Object? pausedAt = _keep,
    int? todayMinutes,
  }) {
    return FocusState(
      taskId: taskId == _keep ? this.taskId : taskId as String?,
      startedAt: startedAt == _keep ? this.startedAt : startedAt as DateTime?,
      paused: paused ?? this.paused,
      pausedAccumMs: pausedAccumMs ?? this.pausedAccumMs,
      pausedAt: pausedAt == _keep ? this.pausedAt : pausedAt as DateTime?,
      todayMinutes: todayMinutes ?? this.todayMinutes,
    );
  }
}

const _keep = Object();

String _todayKey() {
  final d = DateTime.now();
  return 'focus_min_${d.year}-${d.month}-${d.day}';
}

class FocusController extends StateNotifier<FocusState> {
  FocusController() : super(const FocusState()) {
    _load();
  }

  Timer? _timer;
  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = state.copyWith(todayMinutes: _prefs?.getInt(_todayKey()) ?? 0);
  }

  /// Start focusing on [taskId] (or stop if it's already the active one).
  void start(String taskId) {
    if (state.taskId == taskId) {
      stop();
      return;
    }
    if (state.active) _finishLog();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // New object → StateNotifier notifies → UI re-reads elapsed.
      state = state.copyWith();
    });
    state = state.copyWith(
      taskId: taskId,
      startedAt: DateTime.now(),
      paused: false,
      pausedAccumMs: 0,
      pausedAt: null,
    );
  }

  void togglePause() {
    if (!state.active) return;
    if (state.paused) {
      final add = DateTime.now().difference(state.pausedAt!).inMilliseconds;
      state = state.copyWith(
          paused: false, pausedAt: null, pausedAccumMs: state.pausedAccumMs + add);
    } else {
      state = state.copyWith(paused: true, pausedAt: DateTime.now());
    }
  }

  void stop() {
    _finishLog();
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
        taskId: null, startedAt: null, paused: false, pausedAccumMs: 0, pausedAt: null);
  }

  void _finishLog() {
    final mins = state.elapsed.inMinutes;
    if (mins <= 0) return;
    final total = state.todayMinutes + mins;
    _prefs?.setInt(_todayKey(), total);
    state = state.copyWith(todayMinutes: total);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusControllerProvider =
    StateNotifierProvider<FocusController, FocusState>((ref) => FocusController());

/// The id of the task currently in focus (null = none).
final focusedTaskIdProvider =
    Provider<String?>((ref) => ref.watch(focusControllerProvider).taskId);
