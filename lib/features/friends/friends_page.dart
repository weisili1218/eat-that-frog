import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../auth/auth_page.dart';
import '../auth/auth_provider.dart';
import '../settings/settings_provider.dart';
import 'friends_provider.dart';
import 'models.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final signedIn = ref.watch(authUserProvider).valueOrNull != null;

    return ColoredBox(
      color: AppColors.ivoryL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['friendsMono'], style: AppText.mono()),
                const SizedBox(height: 6),
                Text(s['friendsTitle'], style: AppText.title()),
              ],
            ),
          ),
          Expanded(
            child: signedIn
                ? RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () async {
                      ref.read(socialRefreshProvider.notifier).state++;
                      await Future<void>.delayed(const Duration(milliseconds: 250));
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
                      children: [
                        _CommunityTabs(strings: s),
                        const SizedBox(height: 16),
                        _WeeklyCompareCard(strings: s),
                        const SizedBox(height: 14),
                        _FocusingSection(strings: s),
                        _PartnersSection(strings: s),
                        const SizedBox(height: 16),
                        _FeedButton(strings: s),
                        const SizedBox(height: 10),
                        _AddFriendButton(strings: s),
                      ],
                    ),
                  )
                : _SignInGate(strings: s),
          ),
        ],
      ),
    );
  }
}

class _SignInGate extends StatelessWidget {
  const _SignInGate({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 14),
            Text('登入後和好友一起吃青蛙、拚連勝',
                textAlign: TextAlign.center, style: AppText.body(color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            Material(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => showAuthSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(strings['loginSync'], style: AppText.button()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityTabs extends ConsumerWidget {
  const _CommunityTabs({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider).valueOrNull ?? const [];
    final selected = ref.watch(selectedCommunityProvider);
    if (selected == null && communities.isNotEmpty) {
      Future.microtask(() =>
          ref.read(selectedCommunityProvider.notifier).state = communities.first['id'] as String);
    }
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in communities)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: c['name'] as String? ?? '群組',
                active: selected == c['id'],
                onTap: () => ref.read(selectedCommunityProvider.notifier).state = c['id'] as String,
              ),
            ),
          _Chip(
            label: '+ ${strings['newGroupBtn']}',
            active: false,
            dashed: true,
            onTap: () => showCreateGroupSheet(context),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCompareCard extends ConsumerWidget {
  const _WeeklyCompareCard({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(weeklyCompareProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.ivoryL,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ivoryD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings['weeklyCompareLabel'],
              style: AppText.mono(size: 10, color: AppColors.cloud, letterSpacing: 0.1)),
          const SizedBox(height: 6),
          Text(text, style: AppText.body15().copyWith(fontWeight: FontWeight.w500, height: 1.4)),
        ],
      ),
    );
  }
}

class _FocusingSection extends ConsumerWidget {
  const _FocusingSection({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusing = ref.watch(focusingFriendsProvider).valueOrNull ?? const [];
    if (focusing.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(strings['focusingLabel'], color: AppColors.cloud),
        for (final f in focusing)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ivoryL,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ivoryD),
            ),
            child: Row(
              children: [
                _Avatar(profile: f, size: 28, dot: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: f.displayName, style: AppText.body15().copyWith(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        TextSpan(text: '  ${f.focusTask ?? strings['focusingNow']}', style: AppText.body15(color: AppColors.inkSoft).copyWith(fontSize: 13.5)),
                      ])),
                      const SizedBox(height: 2),
                      Text('${strings['focusedForLabel']} ${f.focusMinutes} ${strings['minutesSuffix']}',
                          style: AppText.mono(size: 9.5, color: AppColors.inkSoft, letterSpacing: 0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PartnersSection extends ConsumerWidget {
  const _PartnersSection({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(friendsProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(strings['partnersLabel'], color: AppColors.cloud),
        if (partners.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text(strings['noFriendsYet'], style: AppText.body15(color: AppColors.cloud)),
          ),
        for (final p in partners)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.ivoryL,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ivoryD),
            ),
            child: Row(
              children: [
                _Avatar(profile: p, size: 34),
                const SizedBox(width: 12),
                Expanded(child: Text(p.displayName, style: AppText.cardTitle().copyWith(fontSize: 14.5))),
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text('${p.streak} ${strings['streakDaysSuffix']}',
                    style: AppText.mono(size: 11, color: AppColors.inkSoft, letterSpacing: 0)),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeedButton extends ConsumerWidget {
  const _FeedButton({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cid = ref.watch(selectedCommunityProvider);
    return _WideButton(
      icon: Icons.chat_bubble_outline_rounded,
      label: strings['feedLabel'],
      onTap: cid == null
          ? () => showCreateGroupSheet(context)
          : () => showChatModal(context, cid),
    );
  }
}

class _AddFriendButton extends ConsumerWidget {
  const _AddFriendButton({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(incomingRequestsProvider).valueOrNull?.length ?? 0;
    return _WideButton(
      icon: Icons.person_add_alt_1_outlined,
      label: strings['addFriendBtn'],
      badge: count > 0 ? '$count' : null,
      onTap: () => showAddFriendSheet(context),
    );
  }
}

// ================= Add-friend modal =================

Future<void> showAddFriendSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddFriendSheet(),
    );

class _AddFriendSheet extends ConsumerStatefulWidget {
  const _AddFriendSheet();
  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final incoming = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
    final results = ref.watch(searchResultsProvider(_query)).valueOrNull ?? const [];
    final remote = ref.read(socialRemoteProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.ivoryL,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(title: s['addFriendBtn']),
              if (incoming.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionLabel(s['incomingRequestsLabel'], color: AppColors.accent),
                for (final r in incoming)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.ivoryD)),
                    ),
                    child: Row(
                      children: [
                        _Avatar(profile: r.profile, size: 32),
                        const SizedBox(width: 12),
                        Expanded(child: Text(r.profile.displayName, style: AppText.body15())),
                        GestureDetector(
                          onTap: () async {
                            await remote.declineFriend(r.id);
                            ref.read(socialRefreshProvider.notifier).state++;
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text(s['declineBtn'], style: AppText.pill(color: AppColors.cloud)),
                          ),
                        ),
                        Material(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onTap: () async {
                              await remote.acceptFriend(r.id);
                              ref.read(socialRefreshProvider.notifier).state++;
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              child: Text(s['acceptBtn'], style: AppText.button().copyWith(fontSize: 12.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              _SectionLabel(s['searchFriendsLabel'], color: AppColors.cloud),
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: AppText.body15(),
                cursorColor: AppColors.accent,
                decoration: _inputDeco(s['searchPlaceholder']),
              ),
              const SizedBox(height: 12),
              for (final r in results)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.ivoryD)),
                  ),
                  child: Row(
                    children: [
                      _Avatar(profile: r.profile, size: 30),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r.profile.displayName, style: AppText.body15())),
                      if (r.pending)
                        Text(s['pendingLabel'], style: AppText.pill(color: AppColors.cloud))
                      else
                        GestureDetector(
                          onTap: () async {
                            await remote.sendFriendRequest(r.profile.id);
                            ref.read(socialRefreshProvider.notifier).state++;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s['reqSentToast']), duration: const Duration(seconds: 1)),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.ink),
                            ),
                            child: Text(s['sendRequestBtn'],
                                style: AppText.pill(color: AppColors.ink).copyWith(fontSize: 12.5)),
                          ),
                        ),
                    ],
                  ),
                ),
              if (_query.trim().isNotEmpty && results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: Text(s['noSuggestions'], style: AppText.body15(color: AppColors.cloud))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Create-group modal =================

Future<void> showCreateGroupSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGroupSheet(),
    );

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();
  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _name = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final row = await ref
        .read(socialRemoteProvider)
        .createCommunity(name, memberIds: _selected.toList());
    ref.read(socialRefreshProvider.notifier).state++;
    if (row != null) ref.read(selectedCommunityProvider.notifier).state = row['id'] as String;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final friends = ref.watch(friendsProvider).valueOrNull ?? const [];
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.ivoryL,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(title: s['newGroupBtn']),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                autofocus: true,
                style: AppText.body15(),
                cursorColor: AppColors.accent,
                decoration: _inputDeco(s['newCommunityPlaceholder']),
              ),
              const SizedBox(height: 16),
              _SectionLabel(s['pickMembersLabel'], color: AppColors.cloud),
              if (friends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(s['noFriendsYet'], style: AppText.body15(color: AppColors.cloud)),
                ),
              for (final f in friends)
                GestureDetector(
                  onTap: () => setState(() =>
                      _selected.contains(f.id) ? _selected.remove(f.id) : _selected.add(f.id)),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: _selected.contains(f.id) ? AppColors.ink : Colors.transparent,
                            border: Border.all(color: AppColors.ink, width: 1.4),
                          ),
                          child: _selected.contains(f.id)
                              ? const Icon(Icons.check, size: 13, color: AppColors.ivoryL)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        _Avatar(profile: f, size: 28),
                        const SizedBox(width: 10),
                        Text(f.displayName, style: AppText.body15()),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Material(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: _create,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: Text(s['createGroupBtn'], style: AppText.button())),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Chat modal (full-screen) =================

Future<void> showChatModal(BuildContext context, String communityId) {
  return Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _ChatModal(communityId: communityId),
  ));
}

class _ChatModal extends ConsumerStatefulWidget {
  const _ChatModal({required this.communityId});
  final String communityId;
  @override
  ConsumerState<_ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends ConsumerState<_ChatModal> {
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    _draft.clear();
    await ref.read(socialRemoteProvider).sendMessage(widget.communityId, text);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final myId = ref.watch(myProfileProvider).valueOrNull?.id;
    final byId = ref.watch(allProfilesProvider).valueOrNull ?? const {};
    final msgs = ref.watch(messagesProvider(widget.communityId));

    return Scaffold(
      backgroundColor: AppColors.ivoryL,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 14),
            child: Row(
              children: [
                Expanded(child: Text(s['feedLabel'], style: AppText.frog().copyWith(fontSize: 22))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ivoryD),
                    ),
                    child: const Icon(Icons.close, size: 13, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.ivoryD),
          Expanded(
            child: msgs.when(
              loading: () => const Center(
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))),
              error: (e, _) => Center(child: Text('$e', style: AppText.pill(color: AppColors.cloud))),
              data: (list) => list.isEmpty
                  ? Center(child: Text('—', style: AppText.body15(color: AppColors.cloud)))
                  : ListView(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      children: [
                        for (final m in list.reversed)
                          _Bubble(text: m.text, mine: m.userId == myId, sender: byId[m.userId]),
                      ],
                    ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.ivoryD)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _draft,
                    style: AppText.body15().copyWith(fontSize: 14),
                    cursorColor: AppColors.accent,
                    onSubmitted: (_) => _send(),
                    decoration: _inputDeco(s['chatPlaceholder'], pill: true),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: _send,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      child: Text(s['chatSendBtn'], style: AppText.button()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine, this.sender});
  final String text;
  final bool mine;
  final Profile? sender;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine && sender != null) ...[
            _Avatar(profile: sender!, size: 26),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!mine && sender != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(sender!.displayName, style: AppText.mono(size: 9, color: AppColors.cloud, letterSpacing: 0)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: mine ? AppColors.accent : AppColors.ivoryM,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(text, style: AppText.body15(color: mine ? AppColors.ivoryL : AppColors.ink).copyWith(fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= shared bits =================

InputDecoration _inputDeco(String hint, {bool pill = false}) => InputDecoration(
      hintText: hint,
      hintStyle: AppText.body15(color: AppColors.cloud).copyWith(fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pill ? AppRadius.pill : 14),
        borderSide: const BorderSide(color: AppColors.ivoryD),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pill ? AppRadius.pill : 14),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.frog().copyWith(fontSize: 20)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.ivoryD)),
              child: const Icon(Icons.close, size: 12, color: AppColors.ink),
            ),
          ),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
        child: Text(text, style: AppText.mono(size: 10.5, color: color, letterSpacing: 0.12)),
      );
}

class _WideButton extends StatelessWidget {
  const _WideButton({required this.icon, required this.label, required this.onTap, this.badge});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.ivoryL,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ivoryD),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: AppText.cardTitle().copyWith(fontSize: 14.5))),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(badge!, style: AppText.mono(size: 10, color: AppColors.ivoryL, letterSpacing: 0)),
                ),
            ],
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap, this.dashed = false});
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool dashed;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: active ? AppColors.ink : AppColors.ivoryD),
          ),
          child: Text(label,
              style: AppText.pill(color: active ? AppColors.ivoryL : AppColors.inkSoft).copyWith(fontSize: 13)),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.size, this.dot = false});
  final Profile profile;
  final double size;
  final bool dot;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: profile.color, shape: BoxShape.circle),
            child: Text(profile.initial,
                style: AppText.body(color: AppColors.ivoryL).copyWith(fontSize: size * 0.42, fontWeight: FontWeight.w600)),
          ),
          if (dot)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.diffEasy,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ivoryL, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
