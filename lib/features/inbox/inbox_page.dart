import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../../shared/animations/fade_up.dart';
import 'inbox_provider.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(taskRepositoryProvider).add(text, bucket: TaskBucket.inbox);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const s = AppStrings.zh;
    final inbox = ref.watch(inboxListProvider);
    final later = ref.watch(laterListProvider);
    final someday = ref.watch(somedayListProvider);
    final repo = ref.read(taskRepositoryProvider);

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

          // Quick add
          FadeUp(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _add(),
                      textInputAction: TextInputAction.done,
                      style: AppText.body15(),
                      cursorColor: AppColors.accent,
                      decoration: InputDecoration(
                        hintText: s['inputPlaceholder'],
                        hintStyle: AppText.body15(color: AppColors.cloud),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.ivoryL,
                        enabledBorder: _border(AppColors.ivoryD),
                        focusedBorder: _border(AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: _add,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        child: Text(s['addBtn'], style: AppText.button()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                _sectionLabel(s['unsortedLabel']),
                if (inbox.isEmpty) _emptyLine(s['inboxEmpty']),
                for (var i = 0; i < inbox.length; i++)
                  FadeUp(
                    index: i,
                    child: _UnsortedItem(
                      task: inbox[i],
                      strings: s,
                      onToday: () => repo.setBucket(inbox[i].id, TaskBucket.today),
                      onLater: () => repo.setBucket(inbox[i].id, TaskBucket.later),
                      onSomeday: () => repo.setBucket(inbox[i].id, TaskBucket.someday),
                      onDelete: () => repo.delete(inbox[i].id),
                    ),
                  ),

                const SizedBox(height: 16),
                _sectionLabel(s['laterLabel']),
                if (later.isEmpty) _emptyLine(s['laterEmpty']),
                for (final t in later)
                  _MoveRow(
                    task: t,
                    label: s['moveTodayBtn'],
                    onMove: () => repo.setBucket(t.id, TaskBucket.today),
                  ),

                const SizedBox(height: 16),
                _sectionLabel(s['somedayLabel']),
                if (someday.isEmpty) _emptyLine(s['somedayEmpty']),
                for (final t in someday)
                  _MoveRow(
                    task: t,
                    label: s['moveTodayBtn'],
                    onMove: () => repo.setBucket(t.id, TaskBucket.today),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: c),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
        child: Text(text,
            style: AppText.mono(size: 10.5, color: AppColors.cloud, letterSpacing: 0.12)),
      );

  Widget _emptyLine(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(text, style: AppText.body15(color: AppColors.cloud)),
      );
}

class _UnsortedItem extends StatelessWidget {
  const _UnsortedItem({
    required this.task,
    required this.strings,
    required this.onToday,
    required this.onLater,
    required this.onSomeday,
    required this.onDelete,
  });

  final Task task;
  final AppStrings strings;
  final VoidCallback onToday;
  final VoidCallback onLater;
  final VoidCallback onSomeday;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ivoryD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(task.title, style: AppText.body15())),
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(strings['deleteBtn'],
                      style: AppText.pill(color: AppColors.cloud)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Pill(label: strings['today'], onTap: onToday, primary: true),
              const SizedBox(width: 8),
              _Pill(label: strings['laterLabel'], onTap: onLater),
              const SizedBox(width: 8),
              _Pill(label: strings['somedayLabel'], onTap: onSomeday),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.task, required this.label, required this.onMove});

  final Task task;
  final String label;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ivoryD)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(task.title, style: AppText.body15())),
          const SizedBox(width: 10),
          _Pill(label: label, onTap: onMove),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.primary = false});

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: primary ? AppColors.ink : AppColors.ivoryD),
        ),
        child: Text(
          label,
          style: AppText.pill(color: primary ? AppColors.ink : AppColors.inkSoft),
        ),
      ),
    );
  }
}
