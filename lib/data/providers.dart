import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/database.dart';
import 'remote/supabase_client.dart';
import 'remote/sync_service.dart';
import 'repositories/record_repository.dart';
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
/// Null in local-only mode.
final syncTriggerProvider = Provider<Future<void> Function()?>((ref) {
  final svc = ref.watch(syncServiceProvider);
  return svc?.requestPush;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(db.tasksDao, onLocalChange: ref.watch(syncTriggerProvider));
});

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RecordRepository(db.dailyRecordsDao,
      onLocalChange: ref.watch(syncTriggerProvider));
});

/// Live stream of all non-deleted tasks. Every task view derives from this.
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

/// Live stream of all daily records.
final allRecordsProvider = StreamProvider<List<DailyRecord>>((ref) {
  return ref.watch(recordRepositoryProvider).watchAll();
});
