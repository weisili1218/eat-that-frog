import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation.dart';
import 'core/theme.dart';
import 'data/notifications/notification_provider.dart';
import 'features/today/today_page.dart';
import 'features/inbox/inbox_page.dart';
import 'features/stats/stats_page.dart';
import 'features/friends/friends_page.dart';
import 'features/friends/profile_sync.dart';
import 'features/stats/freeze_award.dart';
import 'features/settings/settings_page.dart';
import 'features/inbox/inbox_provider.dart';
import 'features/settings/settings_provider.dart';
import 'shared/widgets/tab_bar.dart';

/// Root scaffold: tabs, frosted bottom bar, a gear icon, and the Settings
/// overlay.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var tab = ref.watch(currentTabProvider);
    final inboxCount = ref.watch(inboxCountProvider);
    final settingsOpen = ref.watch(settingsOpenProvider);
    final friendsEnabled = ref.watch(settingsProvider).friendsEnabled;
    final s = ref.watch(stringsProvider);
    ref.watch(notificationSchedulerProvider);
    ref.watch(profileSyncProvider);
    ref.watch(freezeAwardProvider);

    // If Friends is off but somehow selected, fall back to Today.
    if (!friendsEnabled && tab == AppTab.friends) tab = AppTab.today;

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
                FriendsPage(),
              ],
            ),
          ),
          Positioned(
            top: 58,
            right: 20,
            child: _GearButton(
              onTap: () => ref.read(settingsOpenProvider.notifier).state = true,
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
              showFriends: friendsEnabled,
              strings: s,
            ),
          ),
          if (settingsOpen) const Positioned.fill(child: SettingsOverlay()),
        ],
      ),
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.ivoryL,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ivoryD),
        ),
        child: const Icon(Icons.settings_outlined, size: 16, color: AppColors.ink),
      ),
    );
  }
}
