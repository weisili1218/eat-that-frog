import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_provider.dart';
import 'notification_service.dart';

/// Re-schedules notifications whenever settings load or change.
/// Activated by [RootShell] watching this provider.
final notificationSchedulerProvider = Provider<void>((ref) {
  ref.listen<SettingsState>(
    settingsProvider,
    (_, next) {
      if (next.loaded) NotificationService.instance.scheduleAll(next);
    },
    fireImmediately: true,
  );
});
