import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/local/subtask.dart';

/// A single checkable subtask line (circular checkbox + text).
class SubtaskRow extends StatelessWidget {
  const SubtaskRow({
    super.key,
    required this.subtask,
    required this.onToggle,
    this.fontSize = 13.5,
    this.boxSize = 17,
  });

  final Subtask subtask;
  final VoidCallback onToggle;
  final double fontSize;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    final done = subtask.done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.ink : Colors.transparent,
                border: Border.all(color: AppColors.ink, width: 1.4),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: boxSize * 0.62, color: AppColors.ivoryL)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtask.title,
              style: AppText.body(color: AppColors.ink).copyWith(
                fontSize: fontSize,
                decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                color: done ? AppColors.ink.withValues(alpha: 0.5) : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
