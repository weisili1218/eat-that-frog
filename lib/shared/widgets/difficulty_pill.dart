import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/theme.dart';

/// Small bordered pill showing a task's difficulty in its colour.
class DifficultyPill extends StatelessWidget {
  const DifficultyPill({super.key, required this.difficulty, required this.strings});

  final Difficulty difficulty;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    final label = switch (difficulty) {
      Difficulty.easy => strings['diffEasy'],
      Difficulty.medium => strings['diffMedium'],
      Difficulty.hard => strings['diffHard'],
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppText.mono(size: 9, color: color, letterSpacing: 0.06),
      ),
    );
  }
}
