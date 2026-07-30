import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_client.dart';

/// All Supabase calls for the social layer (profiles, friends, communities,
/// messages, presence). Every method fails soft: it no-ops / returns empty on
/// any backend error (offline, missing table, RLS) so the UI never throws.
class SocialRemote {
  SupabaseClient get _c => SupabaseService.instance.client;
  String? get uid => SupabaseService.instance.user?.id;
  bool get _ok => SupabaseService.instance.isAvailable && uid != null;
  final _uuid = const Uuid();

  Future<T> _guard<T>(Future<T> Function() body, T fallback) async {
    if (!_ok) return fallback;
    try {
      return await body();
    } catch (e) {
      if (kDebugMode) debugPrint('[social] $e');
      return fallback;
    }
  }

  // ---------------- profiles ----------------

  Future<Map<String, dynamic>?> myProfile() => _guard(
        () async => await _c.from('profiles').select().eq('id', uid!).maybeSingle(),
        null,
      );

  Future<void> upsertMyProfile({
    String? displayName,
    String? avatarColor,
    String? avatarUrl,
    int? streak,
    int? frogsEaten,
  }) =>
      _guard(() async {
        final data = <String, dynamic>{
          'id': uid,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (displayName != null) data['display_name'] = displayName;
        if (avatarColor != null) data['avatar_color'] = avatarColor;
        if (avatarUrl != null) data['avatar_url'] = avatarUrl;
        if (streak != null) data['streak'] = streak;
        if (frogsEaten != null) data['frogs_eaten'] = frogsEaten;
        await _c.from('profiles').upsert(data);
      }, null);

  Future<void> setFocus({String? task, DateTime? startedAt}) => _guard(() async {
        await _c.from('profiles').update({
          'focus_task': task,
          'focus_started_at': startedAt?.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', uid!);
      }, null);

  Future<List<Map<String, dynamic>>> profilesByIds(List<String> ids) => _guard(
        () async {
          if (ids.isEmpty) return const <Map<String, dynamic>>[];
          final rows = await _c.from('profiles').select().inFilter('id', ids);
          return (rows as List).cast<Map<String, dynamic>>();
        },
        const [],
      );

  Future<List<Map<String, dynamic>>> searchProfiles(String query) => _guard(
        () async {
          var q = _c.from('profiles').select();
          if (query.trim().isNotEmpty) q = q.ilike('display_name', '%${query.trim()}%');
          final rows = await q.neq('id', uid!).limit(20);
          return (rows as List).cast<Map<String, dynamic>>();
        },
        const [],
      );

  // ---------------- friendships ----------------

  Future<List<Map<String, dynamic>>> friendships() => _guard(
        () async {
          final rows = await _c
              .from('friendships')
              .select()
              .or('requester_id.eq.$uid,addressee_id.eq.$uid');
          return (rows as List).cast<Map<String, dynamic>>();
        },
        const [],
      );

  /// Send a friend request (status = pending).
  Future<void> sendFriendRequest(String otherId) => _guard(() async {
        await _c.from('friendships').upsert({
          'requester_id': uid,
          'addressee_id': otherId,
          'status': 'pending',
        }, onConflict: 'requester_id,addressee_id');
      }, null);

  /// Incoming pending requests addressed to me: rows of {id, requester_id}.
  Future<List<Map<String, dynamic>>> incomingRequests() => _guard(() async {
        final rows = await _c
            .from('friendships')
            .select('id, requester_id')
            .eq('addressee_id', uid!)
            .eq('status', 'pending');
        return (rows as List).cast<Map<String, dynamic>>();
      }, const []);

  Future<void> acceptFriend(String friendshipId) => _guard(() async {
        await _c.from('friendships').update({'status': 'accepted'}).eq('id', friendshipId);
      }, null);

  Future<void> declineFriend(String friendshipId) => _guard(() async {
        await _c.from('friendships').update({'status': 'declined'}).eq('id', friendshipId);
      }, null);

  // ---------------- communities ----------------

  Future<List<Map<String, dynamic>>> myCommunities() => _guard(
        () async {
          final rows = await _c
              .from('community_members')
              .select('community_id, communities(id, name, created_by)')
              .eq('user_id', uid!);
          return (rows as List)
              .where((r) => r['communities'] != null)
              .map((r) => (r['communities'] as Map).cast<String, dynamic>())
              .toList();
        },
        const [],
      );

  Future<Map<String, dynamic>?> createCommunity(
    String name, {
    List<String> memberIds = const [],
  }) =>
      _guard(
        () async {
          // Generate the id client-side so we don't need a RETURNING select
          // (the community isn't readable until we're a member).
          final id = _uuid.v4();
          await _c.from('communities').insert({
            'id': id,
            'name': name,
            'created_by': uid,
          });
          final members = <String>{uid!, ...memberIds};
          await _c.from('community_members').insert([
            for (final m in members) {'community_id': id, 'user_id': m},
          ]);
          return {'id': id, 'name': name, 'created_by': uid};
        },
        null,
      );

  Future<void> joinCommunity(String communityId) => _guard(() async {
        await _c.from('community_members').upsert({
          'community_id': communityId,
          'user_id': uid,
        });
      }, null);

  // ---------------- messages (realtime) ----------------

  Stream<List<Map<String, dynamic>>> messagesStream(String communityId) {
    if (!_ok) return const Stream.empty();
    return _c
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at')
        .map((rows) => rows.cast<Map<String, dynamic>>())
        .handleError((_) {});
  }

  Future<void> sendMessage(String communityId, String text) => _guard(() async {
        await _c.from('messages').insert({
          'community_id': communityId,
          'user_id': uid,
          'text': text,
        });
      }, null);

  /// Toggle my reaction on a message. [current] is the message's current
  /// reactions map (emoji -> user ids).
  Future<void> toggleReaction(
    String messageId,
    String emoji,
    Map<String, List<String>> current,
  ) =>
      _guard(() async {
        final me = uid!;
        final next = {for (final e in current.entries) e.key: [...e.value]};
        final list = next.putIfAbsent(emoji, () => <String>[]);
        if (list.contains(me)) {
          list.remove(me);
          if (list.isEmpty) next.remove(emoji);
        } else {
          list.add(me);
        }
        await _c.from('messages').update({'reactions': next}).eq('id', messageId);
      }, null);
}
