import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/local/task_x.dart';
import '../../data/providers.dart';

final _todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? const [];
  return tasks.where((t) => t.bucket == TaskBucket.today).toList();
});

final todayFrogsProvider = Provider<List<Task>>((ref) {
  return ref.watch(_todayTasksProvider).where((t) => t.isFrog).toList();
});

final todayTadpolesProvider = Provider<List<Task>>((ref) {
  return ref.watch(_todayTasksProvider).where((t) => t.isTadpole).toList();
});

final todayEmptyProvider = Provider<bool>((ref) {
  return ref.watch(_todayTasksProvider).isEmpty;
});

/// Which tadpole is expanded to show its subtasks (null = none).
final expandedTaskProvider = StateProvider<String?>((ref) => null);
