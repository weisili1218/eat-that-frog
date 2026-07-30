import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../../data/remote/supabase_client.dart';
import '../auth/auth_provider.dart';
import '../settings/settings_provider.dart';
import '../stats/stats_provider.dart';
import '../today/focus_controller.dart';
import 'friends_provider.dart';

/// Pushes my profile (stats, name, colour) and focus presence to Supabase.
/// Activated by [RootShell] watching this provider.
final profileSyncProvider = Provider<void>((ref) {
  Future<void> pushProfile() async {
    final st = ref.read(statsProvider);
    final s = ref.read(settingsProvider);
    final meta = SupabaseService.instance.user?.userMetadata;
    final googlePhoto =
        (meta?['avatar_url'] ?? meta?['picture']) as String?;
    await ref.read(socialRemoteProvider).upsertMyProfile(
          streak: st.streak,
          frogsEaten: st.frogsEaten,
          displayName: s.profileName.trim().isEmpty ? null : s.profileName.trim(),
          avatarColor: s.avatarColor,
          avatarUrl: googlePhoto,
        );
    ref.read(socialRefreshProvider.notifier).state++;
  }

  // On sign-in, push everything.
  ref.listen(authUserProvider, (_, next) {
    if (next.valueOrNull != null) pushProfile();
  });

  // Push cached stats whenever they change.
  ref.listen(statsProvider, (_, next) {
    ref.read(socialRemoteProvider)
        .upsertMyProfile(streak: next.streak, frogsEaten: next.frogsEaten);
  });

  // Push name / colour when edited.
  ref.listen(settingsProvider, (prev, next) {
    if (!next.loaded) return;
    if (prev?.profileName != next.profileName || prev?.avatarColor != next.avatarColor) {
      ref.read(socialRemoteProvider).upsertMyProfile(
            displayName: next.profileName.trim().isEmpty ? null : next.profileName.trim(),
            avatarColor: next.avatarColor,
          );
    }
  });

  // Presence: reflect focus mode on my profile.
  ref.listen(focusedTaskIdProvider, (_, id) {
    final remote = ref.read(socialRemoteProvider);
    if (id == null) {
      remote.setFocus(task: null, startedAt: null);
      return;
    }
    final tasks = ref.read(allTasksProvider).valueOrNull ?? const <Task>[];
    String? title;
    for (final t in tasks) {
      if (t.id == id) title = t.title;
    }
    remote.setFocus(task: title, startedAt: DateTime.now());
  });
});
