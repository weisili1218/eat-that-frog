import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';

/// Tasks awaiting sorting.
final inboxListProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const [];
  return tasks.where((t) => t.bucket == TaskBucket.inbox).toList();
});

final laterListProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const [];
  return tasks.where((t) => t.bucket == TaskBucket.later).toList();
});

final somedayListProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const [];
  return tasks.where((t) => t.bucket == TaskBucket.someday).toList();
});

/// Count of unsorted items — drives the tab-bar unread dot.
final inboxCountProvider = Provider<int>((ref) {
  return ref.watch(inboxListProvider).length;
});

/// Holds the text of the quick-add input.
final inboxDraftProvider = StateProvider<String>((ref) => '');
