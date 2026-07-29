import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/social_remote.dart';
import '../../data/remote/supabase_client.dart';
import '../auth/auth_provider.dart';
import 'models.dart';

final socialRemoteProvider = Provider<SocialRemote>((ref) => SocialRemote());

/// Bump to force friends/requests/communities to refetch.
final socialRefreshProvider = StateProvider<int>((ref) => 0);

String? get _uid => SupabaseService.instance.user?.id;

/// My own profile row.
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authUserProvider);
  ref.watch(socialRefreshProvider);
  final m = await ref.watch(socialRemoteProvider).myProfile();
  return m == null ? null : Profile.fromMap(m);
});

/// Accepted friends ("partners"), ranked by streak then frogs.
final friendsProvider = FutureProvider<List<Profile>>((ref) async {
  ref.watch(authUserProvider);
  ref.watch(socialRefreshProvider);
  final remote = ref.watch(socialRemoteProvider);
  final me = _uid;
  if (me == null) return const [];
  final links = await remote.friendships();
  final ids = <String>{};
  for (final l in links) {
    if (l['status'] != 'accepted') continue;
    final a = l['requester_id'] as String;
    final b = l['addressee_id'] as String;
    ids.add(a == me ? b : a);
  }
  if (ids.isEmpty) return const [];
  final rows = await remote.profilesByIds(ids.toList());
  final list = rows.map(Profile.fromMap).toList()
    ..sort((a, b) {
      final s = b.streak.compareTo(a.streak);
      return s != 0 ? s : b.frogsEaten.compareTo(a.frogsEaten);
    });
  return list;
});

/// Me + friends, for resolving chat sender profiles.
final allProfilesProvider = FutureProvider<Map<String, Profile>>((ref) async {
  final me = await ref.watch(myProfileProvider.future);
  final friends = await ref.watch(friendsProvider.future);
  return {for (final p in [...friends, if (me != null) me]) p.id: p};
});

/// Friends currently in focus mode.
final focusingFriendsProvider = FutureProvider<List<Profile>>((ref) async {
  final friends = await ref.watch(friendsProvider.future);
  return friends.where((f) => f.isFocusing).toList();
});

/// Incoming pending requests: (friendship id, requester profile).
typedef IncomingRequest = ({String id, Profile profile});

final incomingRequestsProvider = FutureProvider<List<IncomingRequest>>((ref) async {
  ref.watch(authUserProvider);
  ref.watch(socialRefreshProvider);
  final remote = ref.watch(socialRemoteProvider);
  final rows = await remote.incomingRequests();
  if (rows.isEmpty) return const [];
  final ids = rows.map((r) => r['requester_id'] as String).toList();
  final profiles = {
    for (final p in await remote.profilesByIds(ids)) p['id'] as String: Profile.fromMap(p)
  };
  final out = <IncomingRequest>[];
  for (final r in rows) {
    final p = profiles[r['requester_id']];
    if (p != null) out.add((id: r['id'] as String, profile: p));
  }
  return out;
});

/// Addressee ids I have an outstanding (pending) request to.
final outgoingPendingIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(socialRefreshProvider);
  final me = _uid;
  if (me == null) return const {};
  final links = await ref.watch(socialRemoteProvider).friendships();
  return {
    for (final l in links)
      if (l['requester_id'] == me && l['status'] == 'pending') l['addressee_id'] as String
  };
});

/// Search result with whether I've already sent a request.
typedef SearchResult = ({Profile profile, bool pending});

final searchResultsProvider =
    FutureProvider.family<List<SearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  final remote = ref.watch(socialRemoteProvider);
  final friends = await ref.watch(friendsProvider.future);
  final pending = await ref.watch(outgoingPendingIdsProvider.future);
  final friendIds = friends.map((f) => f.id).toSet();
  final rows = await remote.searchProfiles(query);
  return rows
      .map(Profile.fromMap)
      .where((p) => !friendIds.contains(p.id))
      .map((p) => (profile: p, pending: pending.contains(p.id)))
      .toList();
});

/// A short "this week" comparison sentence for the friends header card.
final weeklyCompareProvider = Provider<String>((ref) {
  final me = ref.watch(myProfileProvider).valueOrNull;
  final friends = ref.watch(friendsProvider).valueOrNull ?? const [];
  final myStreak = me?.streak ?? 0;
  if (friends.isEmpty) {
    return myStreak > 0 ? '你目前 $myStreak 天連勝，邀請朋友一起比拼吧！' : '邀請朋友，一起養成吃青蛙的習慣';
  }
  final avg = friends.map((f) => f.streak).fold<int>(0, (a, b) => a + b) / friends.length;
  if (myStreak >= avg) {
    return '你 $myStreak 天連勝，領先夥伴平均 ${avg.toStringAsFixed(0)} 天，繼續保持！';
  }
  return '夥伴平均 ${avg.toStringAsFixed(0)} 天連勝，你 $myStreak 天 —— 追上去！';
});

// ---- communities + chat ----

final communitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authUserProvider);
  ref.watch(socialRefreshProvider);
  return ref.watch(socialRemoteProvider).myCommunities();
});

final selectedCommunityProvider = StateProvider<String?>((ref) => null);

final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, communityId) {
  return ref
      .watch(socialRemoteProvider)
      .messagesStream(communityId)
      .map((rows) => rows.map(ChatMessage.fromMap).toList());
});

/// Local, optimistic reaction counts per message id (not yet persisted).
final localReactionsProvider =
    StateProvider<Map<String, Map<String, int>>>((ref) => {});
