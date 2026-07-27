import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import '../animations/done_animation.dart';

/// The PRIORITY card for a today frog. Handles the mark-done animation and the
/// tap-to-restore behaviour when already done.
class FrogCard extends StatefulWidget {
  const FrogCard({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onUnfrog,
    this.strings = AppStrings.zh,
  });

  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback onUnfrog;
  final AppStrings strings;

  @override
  State<FrogCard> createState() => _FrogCardState();
}

class _FrogCardState extends State<FrogCard> {
  final _burst = DoneBurstController();

  void _markDone() {
    _burst.play();
    widget.onToggleDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final s = widget.strings;
    final done = t.done;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ivoryL,
        borderRadius: BorderRadius.circular(AppRadius.frogCard),
        border: Border.all(color: AppColors.ivoryD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s['priorityMono'],
                style: AppText.mono(size: 9.5, color: AppColors.cloud, letterSpacing: 0.1),
              ),
              GestureDetector(
                onTap: widget.onUnfrog,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Text(s['unfrogBtn'], style: AppText.pill(color: AppColors.cloud)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.title,
            style: AppText.frog().copyWith(
              decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
              color: done ? AppColors.ink.withOpacity(0.5) : AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: done ? _doneState(s) : _actionButton(s),
          ),
        ],
      ),
    );

    // When done, tapping the whole card restores it.
    return DoneBurst(
      controller: _burst,
      child: GestureDetector(
        onTap: done ? widget.onToggleDone : null,
        child: card,
      ),
    );
  }

  Widget _actionButton(AppStrings s) {
    return SizedBox(
      key: const ValueKey('action'),
      width: double.infinity,
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: _markDone,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s['markDoneBtn'], style: AppText.button()),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.ivoryL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneState(AppStrings s) {
    return Column(
      key: const ValueKey('done'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s['frogDoneMsg'], style: AppText.emphasis()),
        const SizedBox(height: 6),
        Text(
          s['tapToRestore'],
          style: AppText.mono(size: 9.5, color: AppColors.cloud, letterSpacing: 0.08),
        ),
      ],
    );
  }
}
