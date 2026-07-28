import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';

enum InboxSort { created, difficulty, due }

final inboxSortProvider = StateProvider<InboxSort>((ref) => InboxSort.created);

/// Flat collect list (everything not scheduled for today), sorted per the
/// selected mode.
final inboxListProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const <Task>[];
  final sort = ref.watch(inboxSortProvider);
  final list = tasks.where((t) => t.bucket != TaskBucket.today).toList();

  switch (sort) {
    case InboxSort.created:
      break; // stream already ordered by createdAt
    case InboxSort.difficulty:
      list.sort((a, b) => a.difficulty.order.compareTo(b.difficulty.order));
    case InboxSort.due:
      String key(Task t) => t.dueDate == null
          ? '9999'
          : t.dueDate!.toIso8601String().substring(0, 10);
      list.sort((a, b) => key(a).compareTo(key(b)));
  }
  return list;
});

/// Count of collect items — drives the tab-bar unread dot.
final inboxCountProvider = Provider<int>((ref) => ref.watch(inboxListProvider).length);
