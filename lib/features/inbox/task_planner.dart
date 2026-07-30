import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import '../../data/providers.dart';
import '../../shared/widgets/difficulty_pill.dart';
import '../settings/settings_provider.dart';

/// Opens the auto-planner (hours + energy → suggested today plan).
Future<void> showTaskPlanner(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PlannerSheet(),
    );

class _PlanItem {
  _PlanItem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.minutes,
    required this.isFrog,
    this.selected = true,
  });
  final String id;
  final String title;
  final Difficulty difficulty;
  final int minutes;
  final bool isFrog;
  bool selected;
}

class _PlannerSheet extends ConsumerStatefulWidget {
  const _PlannerSheet();
  @override
  ConsumerState<_PlannerSheet> createState() => _PlannerSheetState();
}

class _PlannerSheetState extends ConsumerState<_PlannerSheet> {
  double _hours = 4;
  double _energy = 3;
  bool _showResult = false;
  List<_PlanItem> _plan = [];

  int _minutesOf(Task t) =>
      t.durationMinutes ??
      (t.difficulty == Difficulty.hard ? 60 : t.difficulty == Difficulty.medium ? 30 : 15);

  // Lower = better fit for the chosen energy.
  int _energyFit(Difficulty d) {
    if (_energy >= 4) return d == Difficulty.hard ? 0 : d == Difficulty.medium ? 1 : 2;
    if (_energy <= 2) return d == Difficulty.easy ? 0 : d == Difficulty.medium ? 1 : 2;
    return d == Difficulty.medium ? 0 : 1;
  }

  void _generate() {
    final tasks = ref.read(allTasksProvider).valueOrNull ?? const <Task>[];
    final inbox = tasks.where((t) => t.bucket == TaskBucket.inbox && !t.done).toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    int urgency(Task t) => t.dueDate?.millisecondsSinceEpoch ?? (1 << 62);

    inbox.sort((a, b) {
      final aO = urgency(a) < now, bO = urgency(b) < now;
      if (aO != bO) return aO ? -1 : 1;
      if (urgency(a) != urgency(b)) return urgency(a).compareTo(urgency(b));
      return _energyFit(a.difficulty).compareTo(_energyFit(b.difficulty));
    });

    var remaining = (_hours * 60).round();
    final picked = <Task>[];
    for (final t in inbox) {
      final m = _minutesOf(t);
      if (m <= remaining || picked.isEmpty) {
        picked.add(t);
        remaining -= m;
      }
      if (remaining <= 0) break;
    }

    Task? frog;
    if (picked.isNotEmpty) {
      final byFit = [...picked]
        ..sort((a, b) => _energyFit(a.difficulty).compareTo(_energyFit(b.difficulty)));
      frog = byFit.first;
    }

    setState(() {
      _plan = [
        for (final t in picked)
          _PlanItem(
            id: t.id,
            title: t.title,
            difficulty: t.difficulty,
            minutes: _minutesOf(t),
            isFrog: frog != null && t.id == frog.id,
          ),
      ];
      _showResult = true;
    });
  }

  Future<void> _save() async {
    final repo = ref.read(taskRepositoryProvider);
    final chosen = _plan.where((p) => p.selected).toList();
    final frogId = chosen.firstWhere((p) => p.isFrog, orElse: () => chosen.isNotEmpty ? chosen.first : _plan.first).id;
    for (final p in chosen) {
      await repo.setBucket(p.id, TaskBucket.today);
      if (p.id == frogId) await repo.setFrog(p.id, true);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ivoryL,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s['plannerTitle'], style: AppText.frog().copyWith(fontSize: 20)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.ivoryD)),
                    child: const Icon(Icons.close, size: 12, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (!_showResult) ..._inputStep(s) else ..._resultStep(s),
          ],
        ),
      ),
    );
  }

  List<Widget> _inputStep(AppStrings s) {
    final energyLabel = s['energyLv${_energy.round()}'];
    return [
      Text('${s['plannerHoursLabel']} · ${_hours.toStringAsFixed(_hours % 1 == 0 ? 0 : 1)} ${s['hoursSuffix']}',
          style: AppText.body15().copyWith(fontWeight: FontWeight.w600)),
      _slider(_hours, 0, 8, 16, (v) => setState(() => _hours = v)),
      const SizedBox(height: 16),
      Text('${s['plannerEnergyLabel']} · $energyLabel',
          style: AppText.body15().copyWith(fontWeight: FontWeight.w600)),
      _slider(_energy, 1, 5, 4, (v) => setState(() => _energy = v)),
      const SizedBox(height: 22),
      _filledBtn(s['plannerGenerateBtn'], _generate),
    ];
  }

  List<Widget> _resultStep(AppStrings s) {
    return [
      Text(s['plannerResultHint'], style: AppText.body15(color: AppColors.inkSoft).copyWith(fontSize: 13.5)),
      const SizedBox(height: 14),
      if (_plan.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Text(s['plannerEmpty'], style: AppText.body15(color: AppColors.cloud))),
        ),
      for (final p in _plan)
        GestureDetector(
          onTap: () => setState(() => p.selected = !p.selected),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.ivoryM, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: p.selected ? AppColors.ink : Colors.transparent,
                    border: Border.all(color: AppColors.ink, width: 1.4),
                  ),
                  child: p.selected ? const Icon(Icons.check, size: 13, color: AppColors.ivoryL) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: AppText.body15()),
                      const SizedBox(height: 3),
                      Text('${p.isFrog ? '🐸 ' : ''}${p.minutes} ${s['minutesSuffix']}',
                          style: AppText.mono(size: 9.5, color: AppColors.inkSoft, letterSpacing: 0)),
                    ],
                  ),
                ),
                DifficultyPill(difficulty: p.difficulty, strings: s),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _outlineBtn(s['plannerBackBtn'], () => setState(() => _showResult = false))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _filledBtn(s['saveBtn'], _plan.isEmpty ? null : _save)),
        ],
      ),
    ];
  }

  Widget _slider(double v, double min, double max, int div, ValueChanged<double> onCh) => SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.accent,
          thumbColor: AppColors.accent,
          inactiveTrackColor: AppColors.ivoryD,
          overlayColor: AppColors.accent.withValues(alpha: 0.1),
        ),
        child: Slider(value: v, min: min, max: max, divisions: div, onChanged: onCh),
      );

  Widget _filledBtn(String label, VoidCallback? onTap) => Material(
        color: onTap == null ? AppColors.cloud : AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(child: Text(label, style: AppText.button())),
          ),
        ),
      );

  Widget _outlineBtn(String label, VoidCallback onTap) => Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: const BorderSide(color: AppColors.ivoryD),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text(label, style: AppText.button(color: AppColors.inkSoft))),
          ),
        ),
      );
}
