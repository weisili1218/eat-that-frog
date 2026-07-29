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
    required this.language,
    required this.profileName,
    required this.avatarColor,
    required this.friendsEnabled,
    this.loaded = false,
  });

  final TimeOfDay dailyReminder;
  final bool weeklyEnabled;
  final TimeOfDay weeklyReview;
  final bool leaveEnabled;
  final AppLocale language;
  final String profileName;
  final String avatarColor; // hex, e.g. #B5502E
  final bool friendsEnabled;
  final bool loaded;

  static const _defaults = SettingsState(
    dailyReminder:
        TimeOfDay(hour: AppConfig.dailyReminderHour, minute: AppConfig.dailyReminderMinute),
    weeklyEnabled: true,
    weeklyReview:
        TimeOfDay(hour: AppConfig.weeklyReviewHour, minute: AppConfig.weeklyReviewMinute),
    leaveEnabled: false,
    language: AppLocale.zh,
    profileName: '',
    avatarColor: '#B5502E',
    friendsEnabled: true,
  );

  SettingsState copyWith({
    TimeOfDay? dailyReminder,
    bool? weeklyEnabled,
    TimeOfDay? weeklyReview,
    bool? leaveEnabled,
    AppLocale? language,
    String? profileName,
    String? avatarColor,
    bool? friendsEnabled,
    bool? loaded,
  }) {
    return SettingsState(
      dailyReminder: dailyReminder ?? this.dailyReminder,
      weeklyEnabled: weeklyEnabled ?? this.weeklyEnabled,
      weeklyReview: weeklyReview ?? this.weeklyReview,
      leaveEnabled: leaveEnabled ?? this.leaveEnabled,
      language: language ?? this.language,
      profileName: profileName ?? this.profileName,
      avatarColor: avatarColor ?? this.avatarColor,
      friendsEnabled: friendsEnabled ?? this.friendsEnabled,
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
      language: (p.getString(AppConfig.prefLanguage) ?? 'zh') == 'en'
          ? AppLocale.en
          : AppLocale.zh,
      profileName: p.getString(AppConfig.prefProfileName) ?? '',
      avatarColor: p.getString(AppConfig.prefAvatarColor) ?? '#B5502E',
      friendsEnabled: p.getBool(AppConfig.prefFriendsEnabled) ?? true,
      loaded: true,
    );
  }

  Future<void> setProfileName(String name) async {
    state = state.copyWith(profileName: name);
    await _prefs?.setString(AppConfig.prefProfileName, name);
  }

  Future<void> setAvatarColor(String hex) async {
    state = state.copyWith(avatarColor: hex);
    await _prefs?.setString(AppConfig.prefAvatarColor, hex);
  }

  Future<void> setFriendsEnabled(bool v) async {
    state = state.copyWith(friendsEnabled: v);
    await _prefs?.setBool(AppConfig.prefFriendsEnabled, v);
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

  Future<void> setLanguage(AppLocale l) async {
    state = state.copyWith(language: l);
    await _prefs?.setString(AppConfig.prefLanguage, l.name);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());

/// The active string table, following the language setting.
final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings.forLocale(ref.watch(settingsProvider).language);
});

String formatTime(TimeOfDay t) {
  final h24 = t.hour;
  final period = h24 < 12 ? '上午' : '下午';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final mm = t.minute.toString().padLeft(2, '0');
  return '$period $h12:$mm';
}
