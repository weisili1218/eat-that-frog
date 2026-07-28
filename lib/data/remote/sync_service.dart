import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../local/database.dart';
import 'completions_remote.dart';
import 'supabase_client.dart';
import 'tasks_remote.dart';

/// Coordinates offline-first sync with Supabase (local-first + Last-Write-Wins).
class SyncService {
  SyncService(this._db);

  final AppDatabase _db;
  final _tasksRemote = TasksRemote();
  final _completionsRemote = CompletionsRemote();

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

    _authSub = SupabaseService.instance.client.auth.onAuthStateChange.listen((_) {
      if (SupabaseService.instance.isSignedIn) syncNow();
    });

    if (_canSync) syncNow();
  }

  Future<void> requestPush() async {
    if (!_canSync) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _pushPending);
  }

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

    final pendingCompletions = await _db.completionsDao.pendingSyncRows();
    if (pendingCompletions.isNotEmpty) {
      await _completionsRemote.upsert(pendingCompletions);
      for (final c in pendingCompletions) {
        await _db.completionsDao.markSynced(c.id);
      }
    }
  }

  Future<void> _pull() async {
    if (!_canSync) return;

    final remoteTasks = await _tasksRemote.fetchSince(_lastPull);
    for (final j in remoteTasks) {
      final companion = TasksRemote.fromJson(j);
      final local = await _db.tasksDao.getById(companion.id.value);
      if (local == null || companion.updatedAt.value.isAfter(local.updatedAt)) {
        await _db.tasksDao.upsert(companion);
      }
    }

    final remoteCompletions = await _completionsRemote.fetchSince(_lastPull);
    for (final j in remoteCompletions) {
      final companion = CompletionsRemote.fromJson(j);
      await _db.completionsDao.upsert(companion);
    }

    _lastPull = DateTime.now();
  }

  void dispose() {
    _debounce?.cancel();
    _connSub?.cancel();
    _authSub?.cancel();
  }
}
