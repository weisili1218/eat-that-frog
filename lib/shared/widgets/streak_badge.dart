import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// Streak pill in the Today header: accent border, Fraunces number + mono unit.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak, this.strings = AppStrings.zh});

  final int streak;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$streak', style: AppText.streakBadge()),
          const SizedBox(width: 6),
          Text(
            strings['streakUnit'],
            style: AppText.mono(size: 9.5, color: AppColors.accent, letterSpacing: 0.08),
          ),
        ],
      ),
    );
  }
}
