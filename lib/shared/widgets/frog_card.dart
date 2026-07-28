import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import '../animations/done_animation.dart';
import 'difficulty_pill.dart';
import 'subtask_row.dart';

/// The PRIORITY card for a today frog (v2): difficulty, edit, focus, subtasks,
/// celebrate animation, and dimming when another task is focused.
class FrogCard extends StatefulWidget {
  const FrogCard({
    super.key,
    required this.task,
    required this.dimmed,
    required this.focused,
    required this.onToggleDone,
    required this.onUnfrog,
    required this.onEdit,
    required this.onFocus,
    required this.onToggleSubtask,
    required this.strings,
  });

  final Task task;
  final bool dimmed;
  final bool focused;
  final VoidCallback onToggleDone;
  final VoidCallback onUnfrog;
  final VoidCallback onEdit;
  final VoidCallback onFocus;
  final void Function(String subtaskId) onToggleSubtask;
  final AppStrings strings;

  @override
  State<FrogCard> createState() => _FrogCardState();
}

class _FrogCardState extends State<FrogCard> {
  final _burst = DoneBurstController();

  void _markDone() {
    _burst.play();
    HapticFeedback.mediumImpact();
    widget.onToggleDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final s = widget.strings;
    final done = t.done;
    final subs = t.subtaskList;

    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ivoryL,
        borderRadius: BorderRadius.circular(AppRadius.frogCard),
        border: Border.all(color: widget.focused ? AppColors.accent : AppColors.ivoryD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(s['priorityMono'],
                      style: AppText.mono(size: 9.5, color: AppColors.cloud, letterSpacing: 0.1)),
                  const SizedBox(width: 8),
                  DifficultyPill(difficulty: t.difficulty, strings: s),
                ],
              ),
              Row(
                children: [
                  _LinkBtn(label: s['editBtn'], onTap: widget.onEdit),
                  const SizedBox(width: 10),
                  _LinkBtn(label: s['unfrogBtn'], onTap: widget.onUnfrog),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: done ? widget.onToggleDone : null,
            child: Text(
              t.title,
              style: AppText.frog().copyWith(
                decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                color: done ? AppColors.ink.withValues(alpha: 0.5) : AppColors.ink,
              ),
            ),
          ),
          if (t.hasMeta) ...[
            const SizedBox(height: 8),
            Text(_metaLine(t, s),
                style: AppText.mono(size: 10, color: AppColors.inkSoft, letterSpacing: 0.04)),
          ],
          const SizedBox(height: 16),
          if (!done)
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: _markDone,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s['markDoneBtn'], style: AppText.button()),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.ivoryL),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _OutlineChip(
                  label: widget.focused ? s['unfocusBtn'] : s['focusBtn'],
                  onTap: widget.onFocus,
                ),
              ],
            )
          else
            GestureDetector(
              onTap: widget.onToggleDone,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey(t.id + done.toString()),
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    builder: (context, v, child) => Transform.scale(scale: v, alignment: Alignment.centerLeft, child: child),
                    child: Text(s['frogDoneMsg'], style: AppText.emphasis()),
                  ),
                  const SizedBox(height: 6),
                  Text(s['tapToRestore'],
                      style: AppText.mono(size: 9.5, color: AppColors.cloud, letterSpacing: 0.08)),
                ],
              ),
            ),
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.ivoryD),
            const SizedBox(height: 4),
            for (final sub in subs)
              SubtaskRow(subtask: sub, onToggle: () => widget.onToggleSubtask(sub.id)),
          ],
        ],
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: widget.dimmed ? 0.38 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DoneBurst(controller: _burst, child: card),
      ),
    );
  }

  String _metaLine(Task t, AppStrings s) {
    final parts = <String>[];
    if (t.dueDate != null) {
      parts.add('${s['dueLabel']} ${t.dueDate!.toIso8601String().substring(0, 10)}');
    }
    if (t.reminderTime != null) parts.add('${s['reminderLabel']} ${t.reminderTime}');
    return parts.join(' · ');
  }
}

class _LinkBtn extends StatelessWidget {
  const _LinkBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Text(label, style: AppText.pill(color: AppColors.cloud)),
        ),
      );
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: const BorderSide(color: AppColors.ink),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Text(label, style: AppText.button(color: AppColors.ink).copyWith(fontSize: 13)),
          ),
        ),
      );
}
