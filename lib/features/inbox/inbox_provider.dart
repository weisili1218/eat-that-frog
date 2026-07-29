import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';

enum InboxSort { created, difficulty, due }

final inboxSortProvider = StateProvider<InboxSort>((ref) => InboxSort.created);

/// Ascending (true) or descending (false) for the current sort.
final inboxSortAscProvider = StateProvider<bool>((ref) => true);

/// Flat collect list (everything not scheduled for today), sorted + directed.
final inboxListProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const <Task>[];
  final sort = ref.watch(inboxSortProvider);
  final asc = ref.watch(inboxSortAscProvider);
  final list = tasks.where((t) => t.bucket != TaskBucket.today).toList();

  switch (sort) {
    case InboxSort.created:
      break; // stream already ordered by createdAt (oldest first)
    case InboxSort.difficulty:
      list.sort((a, b) => a.difficulty.order.compareTo(b.difficulty.order));
    case InboxSort.due:
      String key(Task t) => t.dueDate == null
          ? '9999'
          : t.dueDate!.toIso8601String().substring(0, 10);
      list.sort((a, b) => key(a).compareTo(key(b)));
  }
  if (!asc) return list.reversed.toList();
  return list;
});

final inboxCountProvider = Provider<int>((ref) => ref.watch(inboxListProvider).length);

/// Inbox tasks due within the next 2 days (or overdue) — drives the banner.
final dueSoonCountProvider = Provider<int>((ref) {
  final now = DateTime.now();
  final cutoff = DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
  return ref.watch(inboxListProvider).where((t) {
    final d = t.dueDate;
    return d != null && !d.isAfter(cutoff);
  }).length;
});
