import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/settings/settings_provider.dart';

/// Wraps flutter_local_notifications for the daily frog reminder and the
/// weekly review nudge.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int _dailyId = 1001;
  static const int _weeklyId = 1002;

  static const _daily = (
    title: '今天的青蛙還在等你',
    body: '先把最重要的一件事做掉，今天就贏了。',
  );
  static const _weekly = (
    title: '每週回顧',
    body: '花 5 分鐘整理你的收集匣。',
  );

  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Fall back to UTC if the platform name can't be resolved.
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initSettings);
    _ready = true;
  }

  /// Ask the OS for permission (iOS + Android 13+). Safe to call repeatedly.
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          '提醒',
          channelDescription: '每日青蛙提醒與每週回顧',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Cancel and re-schedule everything from the current [SettingsState].
  Future<void> scheduleAll(SettingsState s) async {
    if (!_ready) await init();
    await _plugin.cancel(_dailyId);
    await _plugin.cancel(_weeklyId);

    await _plugin.zonedSchedule(
      _dailyId,
      _daily.title,
      _daily.body,
      _nextInstanceOfTime(s.dailyReminder.hour, s.dailyReminder.minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (s.weeklyEnabled) {
      await _plugin.zonedSchedule(
        _weeklyId,
        _weekly.title,
        _weekly.body,
        _nextInstanceOfWeekday(
          DateTime.sunday,
          s.weeklyReview.hour,
          s.weeklyReview.minute,
        ),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
