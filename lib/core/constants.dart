import 'package:flutter/widgets.dart';

/// App-wide constants and localized strings.
///
/// Strings are ported from the design prototype (zh / en). The app currently
/// defaults to Traditional Chinese; switch [AppStrings.of] to wire a real
/// locale later.
class AppConfig {
  AppConfig._();

  static const String appName = '先吃掉那隻青蛙';

  /// Default reminder times (24h). Editable in Settings.
  static const int dailyReminderHour = 9;
  static const int dailyReminderMinute = 0;

  /// Weekly review: Sunday 20:00. DateTime.sunday == 7.
  static const int weeklyReviewWeekday = DateTime.sunday;
  static const int weeklyReviewHour = 20;
  static const int weeklyReviewMinute = 0;

  /// SharedPreferences keys.
  static const String prefDailyHour = 'daily_reminder_hour';
  static const String prefDailyMinute = 'daily_reminder_minute';
  static const String prefWeeklyEnabled = 'weekly_review_enabled';
  static const String prefWeeklyHour = 'weekly_review_hour';
  static const String prefWeeklyMinute = 'weekly_review_minute';
  static const String prefLeaveEnabled = 'monthly_leave_enabled';
  static const String prefLastMidnightCheck = 'last_midnight_check';
}

enum AppLocale { zh, en }

/// Localized string table. Values match the prototype's STRINGS map.
class AppStrings {
  const AppStrings(this._m);
  final Map<String, String> _m;

  String operator [](String key) => _m[key] ?? key;

  static AppStrings of(BuildContext context, {AppLocale locale = AppLocale.zh}) {
    return locale == AppLocale.en ? const AppStrings(_en) : const AppStrings(_zh);
  }

  static const AppStrings zh = AppStrings(_zh);
  static const AppStrings en = AppStrings(_en);

  static const Map<String, String> _zh = {
    'todayTab': '今日', 'inboxTab': '收集', 'statsTab': '統計', 'settingsTab': '設定',
    'todayTitle': '今日',
    'frogSectionLabel': '今日青蛙', 'priorityMono': 'PRIORITY',
    'unfrogBtn': '移出青蛙', 'markDoneBtn': '標記完成',
    'frogDoneMsg': '太棒了，今天已經贏了', 'tapToRestore': '點一下卡片可以恢復',
    'emptyCaveat': '先把青蛙吃掉吧', 'emptyToday': '今天還沒有任務', 'goInboxBtn': '前往收集匣',
    'othersLabel': '其他任務', 'setFrogBtn': '設為青蛙',
    'inboxMono': 'COLLECT & SORT', 'inboxTitle': '收集匣',
    'inputPlaceholder': '有什麼想法或待辦...', 'addBtn': '加入',
    'unsortedLabel': '待分類', 'inboxEmpty': '收集匣是空的', 'today': '今日',
    'laterLabel': '之後', 'laterEmpty': '沒有延後的任務',
    'somedayLabel': '待參考', 'somedayEmpty': '沒有待參考的項目',
    'moveTodayBtn': '移到今日', 'deleteBtn': '刪除',
    'progressMono': 'PROGRESS', 'statsTitle': '統計',
    'streakLabel': '連勝', 'streakSub': '今日是否吃了青蛙',
    'hintDone': '太棒了，你今天吃了青蛙', 'hintNotDone': '還沒吃青蛙，等你行動',
    'chartTitle': '近 7 天完成任務數', 'frogRateLabel': '青蛙完成率',
    'frogsEatenLabel': '青蛙已吃', 'tadpolesEatenLabel': '蝌蚪已吃',
    'prefsMono': 'PREFERENCES', 'settingsTitle': '設定',
    'dailyReminder': '每日提醒時間', 'weeklyReminder': '每週回顧提醒',
    'about': '關於「先吃掉那隻青蛙」', 'resetBtn': '重置所有資料',
    'streakUnit': 'DAY',
    'loginSync': '登入 / 同步', 'signInApple': '使用 Apple 登入',
    'signInGoogle': '使用 Google 登入', 'localMode': '本地模式（未登入）',
    'signOut': '登出', 'syncing': '同步中…', 'syncedAt': '已同步',
    'monthlyLeave': '每月請假一次', 'weeklyReviewEnabled': '啟用每週回顧提醒',
    'resetConfirmTitle': '重置所有資料？', 'resetConfirmBody': '這會刪除本機所有任務與連勝紀錄，無法復原。',
    'cancel': '取消', 'confirm': '確認',
    'aboutBody': '「先吃掉那隻青蛙」結合 Eat the Frog 與 GTD 收集系統，'
        '幫你每天先完成最重要的一件事，並用連勝維持動力。',
  };

  static const Map<String, String> _en = {
    'todayTab': 'Today', 'inboxTab': 'Inbox', 'statsTab': 'Stats', 'settingsTab': 'Settings',
    'todayTitle': 'Today',
    'frogSectionLabel': "Today's Frogs", 'priorityMono': 'PRIORITY',
    'unfrogBtn': 'Remove', 'markDoneBtn': 'Mark Done',
    'frogDoneMsg': "Nice — you've already won today", 'tapToRestore': 'Tap card to restore',
    'emptyCaveat': 'Eat that frog first', 'emptyToday': 'No tasks yet today', 'goInboxBtn': 'Go to Inbox',
    'othersLabel': 'Other Tasks', 'setFrogBtn': 'Make Frog',
    'inboxMono': 'COLLECT & SORT', 'inboxTitle': 'Inbox',
    'inputPlaceholder': 'Capture a thought or to-do...', 'addBtn': 'Add',
    'unsortedLabel': 'Unsorted', 'inboxEmpty': 'Inbox is empty', 'today': 'Today',
    'laterLabel': 'Later', 'laterEmpty': 'No later tasks',
    'somedayLabel': 'Someday', 'somedayEmpty': 'No someday items',
    'moveTodayBtn': 'Move to Today', 'deleteBtn': 'Delete',
    'progressMono': 'PROGRESS', 'statsTitle': 'Stats',
    'streakLabel': 'Streak', 'streakSub': 'Ate the frog today?',
    'hintDone': 'You ate the frog today', 'hintNotDone': 'No frog yet — go eat it',
    'chartTitle': 'Tasks Completed · Last 7 Days', 'frogRateLabel': 'Frog Completion Rate',
    'frogsEatenLabel': 'Frogs Eaten', 'tadpolesEatenLabel': 'Tadpoles Eaten',
    'prefsMono': 'PREFERENCES', 'settingsTitle': 'Settings',
    'dailyReminder': 'Daily Reminder', 'weeklyReminder': 'Weekly Review',
    'about': 'About "Eat That Frog"', 'resetBtn': 'Reset All Data',
    'streakUnit': 'DAY',
    'loginSync': 'Sign in / Sync', 'signInApple': 'Sign in with Apple',
    'signInGoogle': 'Sign in with Google', 'localMode': 'Local mode (signed out)',
    'signOut': 'Sign out', 'syncing': 'Syncing…', 'syncedAt': 'Synced',
    'monthlyLeave': 'One leave day per month', 'weeklyReviewEnabled': 'Enable weekly review',
    'resetConfirmTitle': 'Reset all data?', 'resetConfirmBody': 'This deletes all local tasks and streak records. It cannot be undone.',
    'cancel': 'Cancel', 'confirm': 'Confirm',
    'aboutBody': 'Eat That Frog combines the Eat the Frog method with a GTD '
        'collect system to help you finish the most important thing first, '
        'and keeps you motivated with streaks.',
  };
}
