import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation.dart';
import 'core/theme.dart';
import 'data/notifications/notification_provider.dart';
import 'data/streak_controller.dart';
import 'features/today/today_page.dart';
import 'features/inbox/inbox_page.dart';
import 'features/stats/stats_page.dart';
import 'features/settings/settings_page.dart';
import 'features/inbox/inbox_provider.dart';
import 'shared/widgets/tab_bar.dart';

/// Root scaffold hosting the 4 tabs and the frosted bottom bar.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(currentTabProvider);
    final inboxCount = ref.watch(inboxCountProvider);
    // Keep the streak controller alive (recompute on changes / midnight / resume).
    ref.watch(streakControllerProvider);
    // Keep notifications scheduled in sync with settings.
    ref.watch(notificationSchedulerProvider);

    return Scaffold(
      backgroundColor: AppColors.ivoryL,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: tab.index,
              children: const [
                TodayPage(),
                InboxPage(),
                StatsPage(),
                SettingsPage(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FrostedTabBar(
              current: tab,
              onSelect: (t) => ref.read(currentTabProvider.notifier).state = t,
              hasInbox: inboxCount > 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared header used by every tab: mono eyebrow + Fraunces title.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: AppText.mono()),
                const SizedBox(height: 6),
                Text(title, style: AppText.title()),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
