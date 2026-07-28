import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import 'difficulty_pill.dart';
import 'subtask_row.dart';

/// A non-frog today task (v2): checkbox, difficulty, expandable subtasks,
/// focus + make-frog actions, with dimming under focus mode.
class TadpoleRow extends StatelessWidget {
  const TadpoleRow({
    super.key,
    required this.task,
    required this.dimmed,
    required this.expanded,
    required this.onToggleDone,
    required this.onSetFrog,
    required this.onFocus,
    required this.focused,
    required this.onToggleExpand,
    required this.onToggleSubtask,
    required this.strings,
  });

  final Task task;
  final bool dimmed;
  final bool expanded;
  final bool focused;
  final VoidCallback onToggleDone;
  final VoidCallback onSetFrog;
  final VoidCallback onFocus;
  final VoidCallback onToggleExpand;
  final void Function(String subtaskId) onToggleSubtask;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    final subs = task.subtaskList;
    final s = strings;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.38 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.ivoryD)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleDone();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.ink : Colors.transparent,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded, size: 13, color: AppColors.ivoryL)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: AppText.body().copyWith(
                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                      color: done ? AppColors.ink.withValues(alpha: 0.5) : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                DifficultyPill(difficulty: task.difficulty, strings: s),
                if (subs.isNotEmpty)
                  GestureDetector(
                    onTap: onToggleExpand,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right, size: 16, color: AppColors.inkSoft),
                      ),
                    ),
                  ),
                if (!done) ...[
                  const SizedBox(width: 6),
                  _MiniPill(label: focused ? s['unfocusBtn'] : s['focusBtn'], onTap: onFocus),
                  const SizedBox(width: 6),
                  _MiniPill(label: s['setFrogBtn'], onTap: onSetFrog),
                ],
              ],
            ),
          ),
          if (expanded && subs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 34, bottom: 6),
              child: Column(
                children: [
                  for (final sub in subs)
                    SubtaskRow(
                      subtask: sub,
                      boxSize: 16,
                      fontSize: 13,
                      onToggle: () => onToggleSubtask(sub.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.ivoryD),
        ),
        child: Text(label,
            style: AppText.pill(color: AppColors.inkSoft).copyWith(fontSize: 11)),
      ),
    );
  }
}
