import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show Value;

import '../local/database.dart';
import 'records_remote.dart';
import 'supabase_client.dart';
import 'tasks_remote.dart';

/// Coordinates offline-first sync with Supabase.
///
/// Strategy (per spec):
/// - All writes go to Drift first and are flagged `pendingSync`.
/// - When online + signed in, pending rows are pushed (async, non-blocking).
/// - Remote changes are pulled and merged Last-Write-Wins on `updatedAt`.
/// - Connectivity regain and sign-in both trigger a full sync.
class SyncService {
  SyncService(this._db);

  final AppDatabase _db;
  final _tasksRemote = TasksRemote();
  final _recordsRemote = RecordsRemote();

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<dynamic>? _authSub;
  Timer? _debounce;
  bool _syncing = false;
  DateTime? _lastPull;

  bool get _canSync =>
      SupabaseService.instance.isAvailable && SupabaseService.instance.isSignedIn;

  void start() {
    if (!SupabaseService.instance.isAvailable) return;

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) syncNow();
    });

    // Sync right after sign-in (push local first, then pull).
    _authSub = SupabaseService.instance.client.auth.onAuthStateChange.listen((_) {
      if (SupabaseService.instance.isSignedIn) syncNow();
    });

    if (_canSync) syncNow();
  }

  /// Debounced push, invoked by repositories after each local write.
  Future<void> requestPush() async {
    if (!_canSync) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _pushPending);
  }

  /// Full sync: push local changes, then pull remote.
  Future<void> syncNow() async {
    if (!_canSync || _syncing) return;
    _syncing = true;
    try {
      await _pushPending();
      await _pull();
    } catch (_) {
      // Network / auth hiccup — pending rows stay flagged for the next attempt.
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pushPending() async {
    if (!_canSync) return;
    final pendingTasks = await _db.tasksDao.pendingSyncRows();
    if (pendingTasks.isNotEmpty) {
      await _tasksRemote.upsert(pendingTasks);
      for (final t in pendingTasks) {
        await _db.tasksDao.markSynced(t.id);
      }
    }

    final pendingRecords = await _db.dailyRecordsDao.pendingSyncRows();
    if (pendingRecords.isNotEmpty) {
      await _recordsRemote.upsert(pendingRecords);
      for (final r in pendingRecords) {
        await _db.dailyRecordsDao.markSynced(r.id);
      }
    }
  }

  Future<void> _pull() async {
    if (!_canSync) return;

    final remoteTasks = await _tasksRemote.fetchSince(_lastPull);
    for (final j in remoteTasks) {
      final companion = TasksRemote.fromJson(j);
      final local = await _db.tasksDao.getById(companion.id.value);
      final remoteUpdated = companion.updatedAt.value;
      if (local == null || remoteUpdated.isAfter(local.updatedAt)) {
        await _db.tasksDao.upsert(companion);
      }
    }

    final remoteRecords = await _recordsRemote.fetchSince(_lastPull);
    for (final j in remoteRecords) {
      final companion = RecordsRemote.fromJson(j);
      final local = await _db.dailyRecordsDao.getForDate(companion.date.value);
      final remoteUpdated = companion.updatedAt.value;
      if (local == null || remoteUpdated.isAfter(local.updatedAt)) {
        // Preserve the local id so (user,date) uniqueness stays stable.
        await _db.dailyRecordsDao.upsert(
          local == null ? companion : companion.copyWith(id: Value(local.id)),
        );
      }
    }

    _lastPull = DateTime.now();
  }

  void dispose() {
    _debounce?.cancel();
    _connSub?.cancel();
    _authSub?.cancel();
  }
}
