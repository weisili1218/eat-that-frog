import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/database.dart';
import 'remote/supabase_client.dart';
import 'remote/sync_service.dart';
import 'repositories/completion_repository.dart';
import 'repositories/task_repository.dart';

/// The single Drift database instance for the app's lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Offline sync coordinator. Live only when Supabase is configured.
final syncServiceProvider = Provider<SyncService?>((ref) {
  if (!SupabaseService.instance.isAvailable) return null;
  final svc = SyncService(ref.watch(databaseProvider));
  svc.start();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Repositories call this after each local write to trigger a debounced push.
final syncTriggerProvider = Provider<Future<void> Function()?>((ref) {
  final svc = ref.watch(syncServiceProvider);
  return svc?.requestPush;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(
    db.tasksDao,
    db.completionsDao,
    onLocalChange: ref.watch(syncTriggerProvider),
  );
});

final completionRepositoryProvider = Provider<CompletionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CompletionRepository(db.completionsDao,
      onLocalChange: ref.watch(syncTriggerProvider));
});

/// Live stream of all non-deleted tasks.
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

/// Live stream of all completions.
final allCompletionsProvider = StreamProvider<List<Completion>>((ref) {
  return ref.watch(completionRepositoryProvider).watchAll();
});
