import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';

/// A non-frog today task: circular checkbox + title + optional "make frog" pill.
class TadpoleRow extends StatelessWidget {
  const TadpoleRow({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onSetFrog,
    this.strings = AppStrings.zh,
  });

  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback onSetFrog;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ivoryD)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleDone,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
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
                color: done ? AppColors.ink.withOpacity(0.5) : AppColors.ink,
              ),
            ),
          ),
          if (!task.isFrog && !done) ...[
            const SizedBox(width: 8),
            _MakeFrogPill(label: strings['setFrogBtn'], onTap: onSetFrog),
          ],
        ],
      ),
    );
  }
}

class _MakeFrogPill extends StatelessWidget {
  const _MakeFrogPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.ivoryD),
        ),
        child: Text(
          label,
          style: AppText.pill(color: AppColors.inkSoft).copyWith(fontSize: 11.5),
        ),
      ),
    );
  }
}
