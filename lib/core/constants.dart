import 'package:flutter/widgets.dart';

/// App-wide constants and localized strings.
class AppConfig {
  AppConfig._();

  static const String appName = '先吃掉那隻青蛙';

  static const int dailyReminderHour = 9;
  static const int dailyReminderMinute = 0;

  static const int weeklyReviewWeekday = DateTime.sunday;
  static const int weeklyReviewHour = 20;
  static const int weeklyReviewMinute = 0;

  static const String prefDailyHour = 'daily_reminder_hour';
  static const String prefDailyMinute = 'daily_reminder_minute';
  static const String prefWeeklyEnabled = 'weekly_review_enabled';
  static const String prefWeeklyHour = 'weekly_review_hour';
  static const String prefWeeklyMinute = 'weekly_review_minute';
  static const String prefLeaveEnabled = 'monthly_leave_enabled';
  static const String prefLastMidnightCheck = 'last_midnight_check';
  static const String prefLanguage = 'language';
  static const String prefProfileName = 'profile_name';
  static const String prefAvatarColor = 'avatar_color';
  static const String prefFriendsEnabled = 'friends_enabled';
}

enum AppLocale { zh, en }

/// Localized string table.
class AppStrings {
  const AppStrings(this._m);
  final Map<String, String> _m;

  String operator [](String key) => _m[key] ?? key;

  static AppStrings of(BuildContext context, {AppLocale locale = AppLocale.zh}) {
    return locale == AppLocale.en ? en : zh;
  }

  static AppStrings forLocale(AppLocale locale) =>
      locale == AppLocale.en ? en : zh;

  static const AppStrings zh = AppStrings(_zh);
  static const AppStrings en = AppStrings(_en);

  static const Map<String, String> _zh = {
    'todayTab': '今日', 'inboxTab': '收集', 'statsTab': '統計', 'settingsTab': '設定',
    'todayTitle': '今日',
    'frogSectionLabel': '今日青蛙', 'priorityMono': 'PRIORITY',
    'unfrogBtn': '移出青蛙', 'markDoneBtn': '標記完成', 'editBtn': '編輯', 'saveBtn': '儲存',
    'frogDoneMsg': '太棒了，今天已經贏了', 'tapToRestore': '點一下可以恢復',
    'emptyCaveat': '先把青蛙吃掉吧', 'emptyToday': '今天還沒有任務', 'goInboxBtn': '前往收集匣',
    'othersLabel': '其他任務', 'setFrogBtn': '設為青蛙',
    'addSubtaskPlaceholder': '新增子任務...', 'addBtn': '加入',
    'inboxMono': 'CAPTURE', 'inboxTitle': '收集匣', 'inputPlaceholder': '有什麼想法或待辦...',
    'inboxEmpty': '收集匣是空的', 'today': '今日', 'deleteBtn': '刪除',
    'newTaskBtn': '新增任務', 'plannerBtn': '智慧規劃今日',
    'dueSoonSuffix': '項任務即將到期',
    'diffEasy': '簡單', 'diffMedium': '中等', 'diffHard': '困難',
    'focusModeLabel': '專注模式中', 'exitFocus': '結束專注', 'focusBtn': '專注', 'unfocusBtn': '取消專注',
    'pauseFocusBtn': '休息一下', 'resumeFocusBtn': '繼續專注', 'onBreakLabel': '休息中', 'focusTimeLabel': '今日專注時間',
    'dueLabel': '截止', 'reminderLabel': '提醒',
    'sortCreated': '新增順序', 'sortDifficulty': '難度', 'sortDue': '截止日',
    'composerTitleAdd': '新增任務', 'composerTitleEdit': '編輯任務',
    'composerTextPlaceholder': '任務內容...', 'composerSubtasksLabel': '子任務', 'cancelBtn': '取消',
    'progressMono': 'PROGRESS', 'statsTitle': '統計',
    'streakLabel': '連勝', 'streakSub': '今日是否吃了青蛙',
    'hintDone': '太棒了，你今天吃了青蛙', 'hintNotDone': '還沒吃青蛙，等你行動',
    'chartTitle': '近 7 天完成任務數', 'frogRateLabel': '青蛙完成率',
    'frogsEatenLabel': '青蛙已吃', 'tadpolesEatenLabel': '蝌蚪已吃',
    'prefsMono': 'PREFERENCES', 'settingsTitle': '設定', 'langLabel': '語言',
    'dailyReminder': '每日提醒時間', 'weeklyReminder': '每週回顧提醒',
    'about': '關於「先吃掉那隻青蛙」', 'resetBtn': '重置所有資料', 'simulateDayBtn': '模擬進入下一天',
    'streakUnit': 'DAY',
    'friendsTab': '好友', 'friendsMono': 'COMMUNITY', 'friendsTitle': '好友',
    'leaderboardLabel': '排行榜', 'focusingLabel': '正在專注', 'feedLabel': '動態', 'suggestedLabel': '推薦好友',
    'addFriendBtn': '加好友', 'addFriendAction': '加入', 'chatPlaceholder': '說點什麼...', 'chatSendBtn': '送出',
    'newCommunityPlaceholder': '新群組名稱', 'focusedForLabel': '已專注', 'minutesSuffix': '分鐘',
    'lastPlaceTag': '最後一名', 'noSuggestions': '暫無推薦', 'friendsQuickLabel': '好友',
    'showFriendsToggleLabel': '顯示好友分頁', 'profileSectionLabel': '個人檔案', 'nicknameLabel': '暱稱',
    'focusingNow': '專注中', 'you': '你', 'newGroupBtn': '新群組', 'noCommunity': '還沒有群組，建一個吧',
    'weeklyCompareLabel': '本週進度', 'streakDaysSuffix': '天連勝', 'partnersLabel': '夥伴',
    'incomingRequestsLabel': '好友邀請', 'acceptBtn': '接受', 'declineBtn': '忽略',
    'searchFriendsLabel': '搜尋好友', 'searchPlaceholder': '輸入暱稱搜尋...', 'sendRequestBtn': '發送邀請', 'pendingLabel': '邀請中',
    'pickMembersLabel': '選擇成員', 'createGroupBtn': '建立群組', 'noFriendsYet': '還沒有好友，去邀請幾個吧',
    'reqSentToast': '邀請已送出',
    'loginSync': '登入 / 同步', 'signInApple': '使用 Apple 登入',
    'signInGoogle': '使用 Google 登入', 'localMode': '本地模式（未登入）',
    'signOut': '登出', 'syncedAt': '已同步',
    'monthlyLeave': '每月請假一次', 'weeklyReviewEnabled': '啟用每週回顧提醒',
    'resetConfirmTitle': '重置所有資料？', 'resetConfirmBody': '這會刪除本機所有任務與紀錄，無法復原。',
    'cancel': '取消', 'confirm': '確認',
    'aboutBody': '「先吃掉那隻青蛙」結合 Eat the Frog 與 GTD 收集系統，'
        '幫你每天先完成最重要的一件事，並用連勝維持動力。',
  };

  static const Map<String, String> _en = {
    'todayTab': 'Today', 'inboxTab': 'Inbox', 'statsTab': 'Stats', 'settingsTab': 'Settings',
    'todayTitle': 'Today',
    'frogSectionLabel': "Today's Frogs", 'priorityMono': 'PRIORITY',
    'unfrogBtn': 'Remove', 'markDoneBtn': 'Mark Done', 'editBtn': 'Edit', 'saveBtn': 'Save',
    'frogDoneMsg': "Nice — you've already won today", 'tapToRestore': 'Tap to restore',
    'emptyCaveat': 'Eat that frog first', 'emptyToday': 'No tasks yet today', 'goInboxBtn': 'Go to Inbox',
    'othersLabel': 'Other Tasks', 'setFrogBtn': 'Make Frog',
    'addSubtaskPlaceholder': 'Add a subtask...', 'addBtn': 'Add',
    'inboxMono': 'CAPTURE', 'inboxTitle': 'Inbox', 'inputPlaceholder': 'Capture a thought or to-do...',
    'inboxEmpty': 'Inbox is empty', 'today': 'Today', 'deleteBtn': 'Delete',
    'newTaskBtn': 'New Task', 'plannerBtn': 'Smart-plan today',
    'dueSoonSuffix': 'tasks due soon',
    'diffEasy': 'Easy', 'diffMedium': 'Medium', 'diffHard': 'Hard',
    'focusModeLabel': 'Focus mode on', 'exitFocus': 'Exit focus', 'focusBtn': 'Focus', 'unfocusBtn': 'Unfocus',
    'pauseFocusBtn': 'Take a Break', 'resumeFocusBtn': 'Resume Focus', 'onBreakLabel': 'On a break', 'focusTimeLabel': "Today's focus",
    'dueLabel': 'Due', 'reminderLabel': 'Remind',
    'sortCreated': 'Newest', 'sortDifficulty': 'Difficulty', 'sortDue': 'Due Date',
    'composerTitleAdd': 'New Task', 'composerTitleEdit': 'Edit Task',
    'composerTextPlaceholder': 'Task title...', 'composerSubtasksLabel': 'Subtasks', 'cancelBtn': 'Cancel',
    'progressMono': 'PROGRESS', 'statsTitle': 'Stats',
    'streakLabel': 'Streak', 'streakSub': 'Ate the frog today?',
    'hintDone': 'You ate the frog today', 'hintNotDone': 'No frog yet — go eat it',
    'chartTitle': 'Tasks Completed · Last 7 Days', 'frogRateLabel': 'Frog Completion Rate',
    'frogsEatenLabel': 'Frogs Eaten', 'tadpolesEatenLabel': 'Tadpoles Eaten',
    'prefsMono': 'PREFERENCES', 'settingsTitle': 'Settings', 'langLabel': 'Language',
    'dailyReminder': 'Daily Reminder', 'weeklyReminder': 'Weekly Review',
    'about': 'About "Eat That Frog"', 'resetBtn': 'Reset All Data', 'simulateDayBtn': 'Simulate Next Day',
    'streakUnit': 'DAY',
    'friendsTab': 'Friends', 'friendsMono': 'COMMUNITY', 'friendsTitle': 'Friends',
    'leaderboardLabel': 'Leaderboard', 'focusingLabel': 'Focusing now', 'feedLabel': 'Feed', 'suggestedLabel': 'Suggested',
    'addFriendBtn': 'Add', 'addFriendAction': 'Add', 'chatPlaceholder': 'Say something...', 'chatSendBtn': 'Send',
    'newCommunityPlaceholder': 'New group name', 'focusedForLabel': 'Focused for', 'minutesSuffix': 'min',
    'lastPlaceTag': 'Last place', 'noSuggestions': 'No suggestions', 'friendsQuickLabel': 'Friends',
    'showFriendsToggleLabel': 'Show Friends tab', 'profileSectionLabel': 'Profile', 'nicknameLabel': 'Nickname',
    'focusingNow': 'focusing', 'you': 'You', 'newGroupBtn': 'New group', 'noCommunity': 'No group yet — create one',
    'weeklyCompareLabel': 'This week', 'streakDaysSuffix': 'day streak', 'partnersLabel': 'Partners',
    'incomingRequestsLabel': 'Friend Requests', 'acceptBtn': 'Accept', 'declineBtn': 'Ignore',
    'searchFriendsLabel': 'Search Friends', 'searchPlaceholder': 'Search by nickname...', 'sendRequestBtn': 'Send Request', 'pendingLabel': 'Pending',
    'pickMembersLabel': 'Pick members', 'createGroupBtn': 'Create Group', 'noFriendsYet': 'No friends yet — invite some',
    'reqSentToast': 'Request sent',
    'loginSync': 'Sign in / Sync', 'signInApple': 'Sign in with Apple',
    'signInGoogle': 'Sign in with Google', 'localMode': 'Local mode (signed out)',
    'signOut': 'Sign out', 'syncedAt': 'Synced',
    'monthlyLeave': 'One leave day per month', 'weeklyReviewEnabled': 'Enable weekly review',
    'resetConfirmTitle': 'Reset all data?', 'resetConfirmBody': 'This deletes all local tasks and records. It cannot be undone.',
    'cancel': 'Cancel', 'confirm': 'Confirm',
    'aboutBody': 'Eat That Frog combines the Eat the Frog method with a GTD '
        'collect system to help you finish the most important thing first, '
        'and keeps you motivated with streaks.',
  };
}
