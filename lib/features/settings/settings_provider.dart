import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

/// User-configurable preferences, persisted with SharedPreferences.
@immutable
class SettingsState {
  const SettingsState({
    required this.dailyReminder,
    required this.weeklyEnabled,
    required this.weeklyReview,
    required this.leaveEnabled,
    this.loaded = false,
  });

  final TimeOfDay dailyReminder;
  final bool weeklyEnabled;
  final TimeOfDay weeklyReview;
  final bool leaveEnabled;
  final bool loaded;

  static const _defaults = SettingsState(
    dailyReminder:
        TimeOfDay(hour: AppConfig.dailyReminderHour, minute: AppConfig.dailyReminderMinute),
    weeklyEnabled: true,
    weeklyReview:
        TimeOfDay(hour: AppConfig.weeklyReviewHour, minute: AppConfig.weeklyReviewMinute),
    leaveEnabled: false,
  );

  SettingsState copyWith({
    TimeOfDay? dailyReminder,
    bool? weeklyEnabled,
    TimeOfDay? weeklyReview,
    bool? leaveEnabled,
    bool? loaded,
  }) {
    return SettingsState(
      dailyReminder: dailyReminder ?? this.dailyReminder,
      weeklyEnabled: weeklyEnabled ?? this.weeklyEnabled,
      weeklyReview: weeklyReview ?? this.weeklyReview,
      leaveEnabled: leaveEnabled ?? this.leaveEnabled,
      loaded: loaded ?? this.loaded,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState._defaults) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    state = SettingsState(
      dailyReminder: TimeOfDay(
        hour: p.getInt(AppConfig.prefDailyHour) ?? AppConfig.dailyReminderHour,
        minute: p.getInt(AppConfig.prefDailyMinute) ?? AppConfig.dailyReminderMinute,
      ),
      weeklyEnabled: p.getBool(AppConfig.prefWeeklyEnabled) ?? true,
      weeklyReview: TimeOfDay(
        hour: p.getInt(AppConfig.prefWeeklyHour) ?? AppConfig.weeklyReviewHour,
        minute: p.getInt(AppConfig.prefWeeklyMinute) ?? AppConfig.weeklyReviewMinute,
      ),
      leaveEnabled: p.getBool(AppConfig.prefLeaveEnabled) ?? false,
      loaded: true,
    );
  }

  Future<void> setDailyReminder(TimeOfDay t) async {
    state = state.copyWith(dailyReminder: t);
    await _prefs?.setInt(AppConfig.prefDailyHour, t.hour);
    await _prefs?.setInt(AppConfig.prefDailyMinute, t.minute);
  }

  Future<void> setWeeklyEnabled(bool v) async {
    state = state.copyWith(weeklyEnabled: v);
    await _prefs?.setBool(AppConfig.prefWeeklyEnabled, v);
  }

  Future<void> setWeeklyReview(TimeOfDay t) async {
    state = state.copyWith(weeklyReview: t);
    await _prefs?.setInt(AppConfig.prefWeeklyHour, t.hour);
    await _prefs?.setInt(AppConfig.prefWeeklyMinute, t.minute);
  }

  Future<void> setLeaveEnabled(bool v) async {
    state = state.copyWith(leaveEnabled: v);
    await _prefs?.setBool(AppConfig.prefLeaveEnabled, v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());

/// Formats a [TimeOfDay] like the design ("上午 9:00" / "週日 晚上 8:00" handled
/// at the call site).
String formatTime(TimeOfDay t) {
  final h24 = t.hour;
  final period = h24 < 12 ? '上午' : '下午';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final mm = t.minute.toString().padLeft(2, '0');
  return '$period $h12:$mm';
}
