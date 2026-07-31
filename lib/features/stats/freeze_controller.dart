import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Streak-freeze token state (Duolingo-style protection).
@immutable
class FreezeState {
  const FreezeState({
    this.tokens = 2,
    this.usedDays = const {},
    this.milestones = const {},
    this.notice,
    this.loaded = false,
  });

  final int tokens;
  final Set<String> usedDays; // day keys protected by a token
  final Set<int> milestones; // streak lengths already rewarded
  final String? notice;
  final bool loaded;

  FreezeState copyWith({
    int? tokens,
    Set<String>? usedDays,
    Set<int>? milestones,
    Object? notice = _keep,
    bool? loaded,
  }) =>
      FreezeState(
        tokens: tokens ?? this.tokens,
        usedDays: usedDays ?? this.usedDays,
        milestones: milestones ?? this.milestones,
        notice: notice == _keep ? this.notice : notice as String?,
        loaded: loaded ?? this.loaded,
      );
}

const _keep = Object();

String freezeDayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

class FreezeController extends StateNotifier<FreezeState> {
  FreezeController() : super(const FreezeState()) {
    _load();
  }

  SharedPreferences? _p;
  final _rng = Random();

  Future<void> _load() async {
    _p = await SharedPreferences.getInstance();
    state = FreezeState(
      tokens: _p?.getInt('freeze_tokens') ?? 2,
      usedDays: (_p?.getStringList('freeze_used') ?? const []).toSet(),
      milestones: (_p?.getStringList('freeze_ms') ?? const [])
          .map((e) => int.tryParse(e) ?? 0)
          .toSet(),
      loaded: true,
    );
  }

  void _persist() {
    _p?.setInt('freeze_tokens', state.tokens);
    _p?.setStringList('freeze_used', state.usedDays.toList());
    _p?.setStringList('freeze_ms', state.milestones.map((e) => '$e').toList());
  }

  /// 8% chance to earn a token when a task is completed.
  void awardLucky() {
    if (_rng.nextDouble() < 0.08) {
      state = state.copyWith(tokens: state.tokens + 1, notice: '幸運！完成任務獲得一張保護券 🛡️');
      _persist();
    }
  }

  /// Reward a token each time the streak hits a multiple of 5.
  void checkMilestone(int streak) {
    if (streak > 0 && streak % 5 == 0 && !state.milestones.contains(streak)) {
      state = state.copyWith(
        tokens: state.tokens + 1,
        milestones: {...state.milestones, streak},
        notice: '達成 $streak 天連勝，獲得一張保護券！🛡️',
      );
      _persist();
    }
  }

  /// Simulate missing yesterday's frog — consume a token to protect the streak,
  /// or reset if none left.
  void simulateMiss() {
    final y = freezeDayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (state.tokens > 0) {
      state = state.copyWith(
        tokens: state.tokens - 1,
        usedDays: {...state.usedDays, y},
        notice: '連勝保護券已自動使用，連勝延續！🛡️',
      );
    } else {
      state = state.copyWith(notice: '沒有保護券了 —— 明天再把青蛙吃回來！');
    }
    _persist();
  }

  /// Day-rollover check: for each past day the user missed since we last
  /// looked, spend a token to protect the streak (most recent day first).
  /// Runs on launch and on resume — this is what makes freeze tokens real.
  ///
  /// [hadFrogOn] answers "was a frog completed on this day?".
  void applyMissedDays(bool Function(DateTime day) hadFrogOn) {
    if (!state.loaded) return;
    final today = DateTime.now();
    final todayKey = freezeDayKey(today);
    final last = _p?.getString('freeze_last_check');
    if (last == todayKey) return; // already reconciled today

    var tokens = state.tokens;
    final used = {...state.usedDays};
    String? notice;
    var spent = 0;

    // Walk back from yesterday. Stop at the first day we can't cover: the
    // streak is broken there anyway, so older days don't matter.
    for (var i = 1; i <= 30; i++) {
      final day = today.subtract(Duration(days: i));
      final key = freezeDayKey(day);
      if (used.contains(key) || hadFrogOn(day)) break; // day is already covered
      if (tokens <= 0) {
        notice = spent > 0 ? null : '沒有保護券了 —— 連勝重新開始，下次再衝！';
        break;
      }
      tokens -= 1;
      used.add(key);
      spent += 1;
    }

    if (spent > 0) {
      notice = spent == 1
          ? '連勝保護券已自動使用，連勝延續！🛡️'
          : '已自動使用 $spent 張保護券，連勝延續！🛡️';
    }

    if (spent > 0 || notice != null) {
      state = state.copyWith(tokens: tokens, usedDays: used, notice: notice);
      _persist();
    }
    _p?.setString('freeze_last_check', todayKey);
  }

  void dismissNotice() => state = state.copyWith(notice: null);
}

final freezeControllerProvider =
    StateNotifierProvider<FreezeController, FreezeState>((ref) => FreezeController());
