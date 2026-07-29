import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/navigation.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../inbox/task_composer.dart';
import '../../shared/animations/fade_up.dart';
import '../../shared/widgets/frog_card.dart';
import '../../shared/widgets/streak_badge.dart';
import '../../shared/widgets/tab_bar.dart';
import '../../shared/widgets/tadpole_row.dart';
import '../settings/settings_provider.dart';
import '../stats/stats_provider.dart';
import 'focus_controller.dart';
import 'today_provider.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final frogs = ref.watch(todayFrogsProvider);
    final tadpoles = ref.watch(todayTadpolesProvider);
    final isEmpty = ref.watch(todayEmptyProvider);
    final streak = ref.watch(statsProvider).streak;
    final focus = ref.watch(focusControllerProvider);
    final focusedId = focus.taskId;
    final expandedId = ref.watch(expandedTaskProvider);
    final repo = ref.read(taskRepositoryProvider);
    final focusMode = focusedId != null;

    final now = DateTime.now();
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dateMono =
        '${DateFormat('yyyy.MM.dd').format(now)} · ${weekdays[now.weekday - 1]}';

    return ColoredBox(
      color: AppColors.ivoryL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  // Leave room for the top-right gear icon (in the shell).
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: StreakBadge(streak: streak, strings: s),
                  ),
                ],
              ),
            ),
          ),

          if (focusMode)
            _FocusBanner(
              strings: s,
              elapsed: focus.elapsed,
              paused: focus.paused,
              onPause: () => ref.read(focusControllerProvider.notifier).togglePause(),
              onExit: () => ref.read(focusControllerProvider.notifier).stop(),
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
              children: [
                if (frogs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                    child: Text('${s['frogSectionLabel']} · ${frogs.length}',
                        style: AppText.mono(size: 10.5, color: AppColors.accent, letterSpacing: 0.12)),
                  ),
                  for (var i = 0; i < frogs.length; i++)
                    FadeUp(
                      index: i,
                      child: FrogCard(
                        task: frogs[i],
                        focused: focusedId == frogs[i].id,
                        dimmed: focusMode && focusedId != frogs[i].id,
                        strings: s,
                        onToggleDone: () => repo.toggleDone(frogs[i]),
                        onUnfrog: () => repo.setFrog(frogs[i].id, false),
                        onEdit: () => showTaskComposer(context, editing: frogs[i]),
                        onFocus: () => _toggleFocus(ref, frogs[i].id),
                        onToggleSubtask: (subId) => repo.toggleSubtask(frogs[i], subId),
                      ),
                    ),
                ],

                if (isEmpty)
                  _EmptyState(strings: s, onGoInbox: () {
                    ref.read(currentTabProvider.notifier).state = AppTab.inbox;
                  }),

                if (tadpoles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
                    child: Text(s['othersLabel'],
                        style: AppText.mono(size: 10.5, color: AppColors.cloud, letterSpacing: 0.12)),
                  ),
                  for (var i = 0; i < tadpoles.length; i++)
                    FadeUp(
                      index: i,
                      child: TadpoleRow(
                        task: tadpoles[i],
                        focused: focusedId == tadpoles[i].id,
                        dimmed: focusMode && focusedId != tadpoles[i].id,
                        expanded: expandedId == tadpoles[i].id,
                        strings: s,
                        onToggleDone: () => repo.toggleDone(tadpoles[i]),
                        onSetFrog: () => repo.setFrog(tadpoles[i].id, true),
                        onFocus: () => _toggleFocus(ref, tadpoles[i].id),
                        onToggleExpand: () => _toggleExpand(ref, tadpoles[i].id),
                        onToggleSubtask: (subId) => repo.toggleSubtask(tadpoles[i], subId),
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

  void _toggleFocus(WidgetRef ref, String id) {
    ref.read(focusControllerProvider.notifier).start(id); // start() toggles off if same
  }

  void _toggleExpand(WidgetRef ref, String id) {
    final cur = ref.read(expandedTaskProvider);
    ref.read(expandedTaskProvider.notifier).state = cur == id ? null : id;
  }
}

class _FocusBanner extends StatelessWidget {
  const _FocusBanner({
    required this.strings,
    required this.elapsed,
    required this.paused,
    required this.onPause,
    required this.onExit,
  });
  final dynamic strings;
  final Duration elapsed;
  final bool paused;
  final VoidCallback onPause;
  final VoidCallback onExit;

  String get _clock {
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final sec = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ivoryM,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(paused ? strings['onBreakLabel'] : strings['focusModeLabel'],
              style: AppText.mono(size: 10, color: AppColors.accent, letterSpacing: 0.08)),
          const SizedBox(width: 10),
          Text(_clock,
              style: AppText.mono(size: 13, color: AppColors.ink, letterSpacing: 0.04)),
          const Spacer(),
          GestureDetector(
            onTap: onPause,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.ivoryD),
              ),
              child: Text(paused ? strings['resumeFocusBtn'] : strings['pauseFocusBtn'],
                  style: AppText.pill(color: AppColors.ink).copyWith(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onExit,
            behavior: HitTestBehavior.opaque,
            child: Text(strings['exitFocus'], style: AppText.pill(color: AppColors.inkSoft)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings, required this.onGoInbox});
  final dynamic strings;
  final VoidCallback onGoInbox;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
        child: Column(
          children: [
            Transform.rotate(
              angle: -0.017,
              child: Text(strings['emptyCaveat'], style: AppText.caveat()),
            ),
            const SizedBox(height: 16),
            Text(strings['emptyToday'],
                style: AppText.body(color: AppColors.inkSoft), textAlign: TextAlign.center),
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
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.ivoryL),
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
