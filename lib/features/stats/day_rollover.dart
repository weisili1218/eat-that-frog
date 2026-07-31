import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';
import 'freeze_controller.dart';

/// Reconciles missed days on launch, on resume, and whenever completions load —
/// spending freeze tokens so a missed day doesn't silently break the streak.
///
/// Without this the tokens are decorative: nothing else consumes them.
final dayRolloverProvider = Provider<DayRollover>((ref) {
  final r = DayRollover(ref);
  r.init();
  ref.onDispose(r.dispose);
  return r;
});

class DayRollover with WidgetsBindingObserver {
  DayRollover(this._ref);
  final Ref _ref;
  ProviderSubscription<AsyncValue<List<Completion>>>? _sub;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    // Completions arrive async; reconcile once they're available (and on any
    // later change, which is cheap because the check self-guards per day).
    _sub = _ref.listen<AsyncValue<List<Completion>>>(
      allCompletionsProvider,
      (_, next) {
        if (next.hasValue) _reconcile();
      },
      fireImmediately: true,
    );
  }

  void _reconcile() {
    final completions = _ref.read(allCompletionsProvider).valueOrNull;
    if (completions == null) return;

    bool hadFrogOn(DateTime day) => completions.any((c) =>
        c.type == CompletionType.frog &&
        c.date.year == day.year &&
        c.date.month == day.month &&
        c.date.day == day.day);

    _ref.read(freezeControllerProvider.notifier).applyMissedDays(hadFrogOn);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reconcile();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.close();
  }
}
