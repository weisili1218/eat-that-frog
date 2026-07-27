import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import '../../data/providers.dart';

/// Tasks in the `today` bucket (empty while the stream is loading).
final _todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const [];
  return tasks.where((t) => t.bucket == TaskBucket.today).toList();
});

/// Today's frogs (priority cards).
final todayFrogsProvider = Provider<List<Task>>((ref) {
  return ref.watch(_todayTasksProvider).where((t) => t.isFrog).toList();
});

/// Today's non-frog tasks (tadpoles).
final todayTadpolesProvider = Provider<List<Task>>((ref) {
  return ref.watch(_todayTasksProvider).where((t) => t.isTadpole).toList();
});

/// True when there are no tasks scheduled for today at all → empty state.
final todayEmptyProvider = Provider<bool>((ref) {
  return ref.watch(_todayTasksProvider).isEmpty;
});
