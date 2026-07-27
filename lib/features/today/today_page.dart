import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/navigation.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../shared/animations/fade_up.dart';
import '../../shared/widgets/frog_card.dart';
import '../../shared/widgets/streak_badge.dart';
import '../../shared/widgets/tab_bar.dart';
import '../../shared/widgets/tadpole_row.dart';
import '../stats/stats_provider.dart';
import 'today_provider.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const s = AppStrings.zh;
    final frogs = ref.watch(todayFrogsProvider);
    final tadpoles = ref.watch(todayTadpolesProvider);
    final isEmpty = ref.watch(todayEmptyProvider);
    final streak = ref.watch(statsProvider).streak;
    final repo = ref.read(taskRepositoryProvider);

    final now = DateTime.now();
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dateMono =
        '${DateFormat('yyyy.MM.dd').format(now)} · ${weekdays[now.weekday - 1]}';

    return ColoredBox(
      color: AppColors.ivoryL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          FadeUp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 58, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateMono, style: AppText.mono()),
                        const SizedBox(height: 6),
                        Text(s['todayTitle'], style: AppText.title()),
                      ],
                    ),
                  ),
                  StreakBadge(streak: streak),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
              children: [
                if (frogs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                    child: Text(
                      '${s['frogSectionLabel']} · ${frogs.length}',
                      style: AppText.mono(
                          size: 10.5, color: AppColors.accent, letterSpacing: 0.12),
                    ),
                  ),
                  for (var i = 0; i < frogs.length; i++)
                    FadeUp(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FrogCard(
                          task: frogs[i],
                          onToggleDone: () => repo.toggleDone(frogs[i]),
                          onUnfrog: () => repo.setFrog(frogs[i].id, false),
                        ),
                      ),
                    ),
                ],

                if (isEmpty) _EmptyState(strings: s, onGoInbox: () {
                  ref.read(currentTabProvider.notifier).state = AppTab.inbox;
                }),

                if (tadpoles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
                    child: Text(
                      s['othersLabel'],
                      style: AppText.mono(
                          size: 10.5, color: AppColors.cloud, letterSpacing: 0.12),
                    ),
                  ),
                  for (var i = 0; i < tadpoles.length; i++)
                    FadeUp(
                      index: i,
                      child: TadpoleRow(
                        task: tadpoles[i],
                        onToggleDone: () => repo.toggleDone(tadpoles[i]),
                        onSetFrog: () => repo.setFrog(tadpoles[i].id, true),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings, required this.onGoInbox});

  final AppStrings strings;
  final VoidCallback onGoInbox;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
        child: Column(
          children: [
            Transform.rotate(
              angle: -0.017, // ~ -1deg
              child: Text(strings['emptyCaveat'], style: AppText.caveat()),
            ),
            const SizedBox(height: 16),
            Text(
              strings['emptyToday'],
              style: AppText.body(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: onGoInbox,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(strings['goInboxBtn'], style: AppText.button()),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.ivoryL),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
