import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/subtask.dart';
import '../../data/local/task_x.dart';
import '../../data/providers.dart';
import '../settings/settings_provider.dart';

/// Opens the add/edit task composer as a modal bottom sheet.
Future<void> showTaskComposer(BuildContext context, {Task? editing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _Composer(editing: editing),
  );
}

class _Composer extends ConsumerStatefulWidget {
  const _Composer({this.editing});
  final Task? editing;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  late final TextEditingController _text =
      TextEditingController(text: widget.editing?.title ?? '');
  final _subDraft = TextEditingController();
  final _uuid = const Uuid();

  late Difficulty _difficulty = widget.editing?.difficulty ?? Difficulty.medium;
  late DateTime? _due = widget.editing?.dueDate;
  late String? _reminder = widget.editing?.reminderTime;
  late List<Subtask> _subtasks = [...?widget.editing?.subtaskList];

  @override
  void dispose() {
    _text.dispose();
    _subDraft.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final t = _subDraft.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _subtasks = [..._subtasks, Subtask(id: _uuid.v4(), title: t)];
      _subDraft.clear();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _pickReminder() async {
    final parts = _reminder?.split(':');
    final init = parts != null && parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked =
        await showTimePicker(context: context, initialTime: init, builder: _pickerTheme);
    if (picked != null) {
      setState(() => _reminder =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Widget _pickerTheme(BuildContext context, Widget? child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.light(primary: AppColors.accent)),
        child: child!,
      );

  Future<void> _save() async {
    final title = _text.text.trim();
    if (title.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final repo = ref.read(taskRepositoryProvider);
    if (widget.editing == null) {
      await repo.add(
        title: title,
        difficulty: _difficulty,
        dueDate: _due,
        reminderTime: _reminder,
        subtasks: _subtasks,
      );
    } else {
      await repo.edit(
        widget.editing!.id,
        title: title,
        difficulty: _difficulty,
        dueDate: _due,
        reminderTime: _reminder,
        subtasks: _subtasks,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
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
                  Text(
                    widget.editing == null ? s['composerTitleAdd'] : s['composerTitleEdit'],
                    style: AppText.frog().copyWith(fontSize: 20),
                  ),
                  _CircleClose(onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _text,
                autofocus: widget.editing == null,
                style: AppText.body15(),
                cursorColor: AppColors.accent,
                decoration: _inputDecoration(s['composerTextPlaceholder']),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final d in Difficulty.values) ...[
                    Expanded(child: _DiffButton(
                      difficulty: d,
                      selected: _difficulty == d,
                      strings: s,
                      onTap: () => setState(() => _difficulty = d),
                    )),
                    if (d != Difficulty.hard) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetaButton(
                      icon: Icons.event_outlined,
                      label: _due == null
                          ? s['dueLabel']
                          : '${s['dueLabel']} ${_due!.toIso8601String().substring(0, 10)}',
                      onTap: _pickDate,
                      onClear: _due == null ? null : () => setState(() => _due = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaButton(
                      icon: Icons.access_time,
                      label: _reminder == null ? s['reminderLabel'] : '${s['reminderLabel']} $_reminder',
                      onTap: _pickReminder,
                      onClear: _reminder == null ? null : () => setState(() => _reminder = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(s['composerSubtasksLabel'],
                  style: AppText.mono(size: 10, color: AppColors.cloud, letterSpacing: 0.1)),
              const SizedBox(height: 8),
              for (final sub in _subtasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(sub.title, style: AppText.body15())),
                      GestureDetector(
                        onTap: () => setState(() => _subtasks = _subtasks.where((x) => x.id != sub.id).toList()),
                        child: Text(s['deleteBtn'], style: AppText.pill(color: AppColors.cloud)),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subDraft,
                      onSubmitted: (_) => _addSubtask(),
                      style: AppText.body15().copyWith(fontSize: 13),
                      cursorColor: AppColors.accent,
                      decoration: _inputDecoration(s['addSubtaskPlaceholder'], dense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(label: s['addBtn'], onTap: _addSubtask),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _OutlineBtn(label: s['cancelBtn'], onTap: () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _FilledBtn(label: s['saveBtn'], onTap: _save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {bool dense = false}) => InputDecoration(
        hintText: hint,
        hintStyle: AppText.body15(color: AppColors.cloud).copyWith(fontSize: dense ? 13 : 15.5),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: dense ? 10 : 14, vertical: dense ? 8 : 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dense ? 10 : 14),
          borderSide: const BorderSide(color: AppColors.ivoryD),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dense ? 10 : 14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      );
}

class _DiffButton extends StatelessWidget {
  const _DiffButton({
    required this.difficulty,
    required this.selected,
    required this.strings,
    required this.onTap,
  });
  final Difficulty difficulty;
  final bool selected;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    final label = switch (difficulty) {
      Difficulty.easy => strings['diffEasy'],
      Difficulty.medium => strings['diffMedium'],
      Difficulty.hard => strings['diffHard'],
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: AppText.pill(color: selected ? AppColors.ivoryL : color)
              .copyWith(fontSize: 12.5),
        ),
      ),
    );
  }
}

class _MetaButton extends StatelessWidget {
  const _MetaButton({required this.icon, required this.label, required this.onTap, this.onClear});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ivoryD),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.inkSoft),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body15(color: AppColors.ink).copyWith(fontSize: 13)),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: AppColors.cloud),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleClose extends StatelessWidget {
  const _CircleClose({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ivoryD),
          ),
          child: const Icon(Icons.close, size: 13, color: AppColors.ink),
        ),
      );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.ivoryD),
          ),
          child: Text(label, style: AppText.pill(color: AppColors.inkSoft)),
        ),
      );
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
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

class _FilledBtn extends StatelessWidget {
  const _FilledBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text(label, style: AppText.button())),
          ),
        ),
      );
}
