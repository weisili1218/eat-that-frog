import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import '../../data/providers.dart';
import '../../shared/animations/fade_up.dart';
import '../../shared/widgets/difficulty_pill.dart';
import '../../shared/widgets/subtask_row.dart';
import '../settings/settings_provider.dart';
import 'inbox_provider.dart';
import 'task_composer.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final list = ref.watch(inboxListProvider);
    final sort = ref.watch(inboxSortProvider);
    final asc = ref.watch(inboxSortAscProvider);
    final dueSoon = ref.watch(dueSoonCountProvider);

    return ColoredBox(
      color: AppColors.ivoryL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeUp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 58, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['inboxMono'], style: AppText.mono()),
                  const SizedBox(height: 6),
                  Text(s['inboxTitle'], style: AppText.title()),
                ],
              ),
            ),
          ),
          FadeUp(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Column(
                children: [
                  if (dueSoon > 0) ...[
                    _DueSoonBanner(text: '$dueSoon ${s['dueSoonSuffix']}'),
                    const SizedBox(height: 10),
                  ],
                  _NewTaskButton(label: s['newTaskBtn'], onTap: () => showTaskComposer(context)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SortToggle(
                          current: sort,
                          strings: s,
                          onSelect: (m) => ref.read(inboxSortProvider.notifier).state = m,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SortDirButton(
                        asc: asc,
                        onTap: () => ref.read(inboxSortAscProvider.notifier).state = !asc,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Text(s['inboxEmpty'], style: AppText.body15(color: AppColors.cloud)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: list.length,
                    itemBuilder: (context, i) => FadeUp(
                      index: i.clamp(0, 8),
                      child: _InboxCard(task: list[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InboxCard extends ConsumerWidget {
  const _InboxCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final repo = ref.read(taskRepositoryProvider);
    final subs = task.subtaskList;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.ivoryL,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ivoryD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DifficultyPill(difficulty: task.difficulty, strings: s),
              const SizedBox(width: 10),
              Expanded(child: Text(task.title, style: AppText.body15())),
            ],
          ),
          if (task.hasMeta) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(_metaLine(task, s),
                  style: AppText.mono(size: 10, color: AppColors.inkSoft, letterSpacing: 0.04)),
            ),
          ],
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.ivoryD),
            const SizedBox(height: 4),
            for (final sub in subs)
              SubtaskRow(
                subtask: sub,
                boxSize: 16,
                fontSize: 13,
                onToggle: () => repo.toggleSubtask(task, sub.id),
              ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _TextAction(
                label: s['editBtn'],
                color: AppColors.cloud,
                onTap: () => showTaskComposer(context, editing: task),
              ),
              const SizedBox(width: 14),
              _TextAction(
                label: s['deleteBtn'],
                color: AppColors.cloud,
                onTap: () => repo.delete(task.id),
              ),
              const SizedBox(width: 14),
              _TextAction(
                label: '${s['today']} →',
                color: AppColors.accent,
                bold: true,
                onTap: () => repo.setBucket(task.id, TaskBucket.today),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _metaLine(Task t, s) {
    final parts = <String>[];
    if (t.dueDate != null) {
      parts.add('${s['dueLabel']} ${t.dueDate!.toIso8601String().substring(0, 10)}');
    }
    if (t.reminderTime != null) parts.add('${s['reminderLabel']} ${t.reminderTime}');
    return parts.join(' · ');
  }
}

class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DottedBorderBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('+',
                style: TextStyle(fontSize: 16, height: 1, color: AppColors.inkSoft)),
            const SizedBox(width: 8),
            Text(label, style: AppText.button(color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

/// A dashed-border container (Flutter has no native dashed border).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        child: child,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ivoryD
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DueSoonBanner extends StatelessWidget {
  const _DueSoonBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent),
        ),
        child: Text(
          text,
          style: AppText.body15(color: AppColors.accent).copyWith(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      );
}

class _SortDirButton extends StatelessWidget {
  const _SortDirButton({required this.asc, required this.onTap});
  final bool asc;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.ivoryL,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ivoryD),
          ),
          child: AnimatedRotation(
            turns: asc ? 0 : 0.5,
            duration: const Duration(milliseconds: 150),
            child: const Icon(Icons.arrow_downward, size: 15, color: AppColors.ink),
          ),
        ),
      );
}

class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.current, required this.strings, required this.onSelect});
  final InboxSort current;
  final dynamic strings;
  final ValueChanged<InboxSort> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ivoryM,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          _seg(strings['sortCreated'], InboxSort.created),
          _seg(strings['sortDifficulty'], InboxSort.difficulty),
          _seg(strings['sortDue'], InboxSort.due),
        ],
      ),
    );
  }

  Widget _seg(String label, InboxSort mode) {
    final active = current == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(mode),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.ivoryL : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: active
                ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.12), blurRadius: 3, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: AppText.pill(color: active ? AppColors.ink : AppColors.cloud),
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.color, required this.onTap, this.bold = false});
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: AppText.pill(color: color)
            .copyWith(fontSize: 12.5, fontWeight: bold ? FontWeight.w600 : FontWeight.w500),
      ),
    );
  }
}
