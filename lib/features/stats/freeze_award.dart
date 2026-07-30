import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/providers.dart';
import 'freeze_controller.dart';
import 'stats_provider.dart';

/// Awards freeze tokens on new completions (8% luck) and streak milestones
/// (every 5 days). Activated by [RootShell] watching this provider.
final freezeAwardProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<Completion>>>(allCompletionsProvider, (prev, next) {
    final before = prev?.valueOrNull?.length ?? 0;
    final after = next.valueOrNull?.length ?? 0;
    if (after > before) ref.read(freezeControllerProvider.notifier).awardLucky();
  });

  ref.listen<StatsData>(statsProvider, (_, next) {
    ref.read(freezeControllerProvider.notifier).checkMilestone(next.streak);
  });
});
