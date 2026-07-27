import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../shared/animations/fade_up.dart';
import '../auth/auth_page.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const s = AppStrings.zh;
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final cloud = ref.watch(cloudAvailableProvider);

    return ColoredBox(
      color: AppColors.ivoryL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeUp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 58, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['prefsMono'], style: AppText.mono()),
                  const SizedBox(height: 6),
                  Text(s['settingsTitle'], style: AppText.title()),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
              children: [
                // ---- Account / sync ----
                FadeUp(
                  index: 1,
                  child: _Card(children: [
                    _Tappable(
                      label: user != null
                          ? (user.email ?? user.userMetadata?['name']?.toString() ?? '已登入')
                          : (cloud ? s['loginSync'] : s['localMode']),
                      value: user != null ? s['syncedAt'] : null,
                      onTap: () async {
                        if (user != null) {
                          await ref.read(authControllerProvider).signOut();
                        } else {
                          await showAuthSheet(context);
                        }
                      },
                      trailingText: user != null ? s['signOut'] : null,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ---- Reminders ----
                FadeUp(
                  index: 2,
                  child: _Card(children: [
                    _Tappable(
                      label: s['dailyReminder'],
                      value: formatTime(settings.dailyReminder),
                      onTap: () async {
                        final picked = await _pickTime(context, settings.dailyReminder);
                        if (picked != null) {
                          await ref.read(settingsProvider.notifier).setDailyReminder(picked);
                        }
                      },
                    ),
                    const _Divider(),
                    _Tappable(
                      label: s['weeklyReminder'],
                      value: settings.weeklyEnabled
                          ? '週日 ${formatTime(settings.weeklyReview)}'
                          : '關閉',
                      onTap: () async {
                        final picked = await _pickTime(context, settings.weeklyReview);
                        if (picked != null) {
                          await ref.read(settingsProvider.notifier).setWeeklyReview(picked);
                        }
                      },
                    ),
                    const _Divider(),
                    _SwitchRow(
                      label: s['weeklyReviewEnabled'],
                      value: settings.weeklyEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setWeeklyEnabled(v),
                    ),
                    const _Divider(),
                    _SwitchRow(
                      label: s['monthlyLeave'],
                      value: settings.leaveEnabled,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setLeaveEnabled(v),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ---- About ----
                FadeUp(
                  index: 3,
                  child: _Card(children: [
                    _Tappable(
                      label: s['about'],
                      onTap: () => _showAbout(context, s),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ---- Reset ----
                FadeUp(
                  index: 4,
                  child: _OutlineButton(
                    label: s['resetBtn'],
                    onTap: () => _confirmReset(context, ref, s),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
  }

  void _showAbout(BuildContext context, AppStrings s) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.ivoryL,
        title: Text(AppConfig.appName, style: AppText.frog().copyWith(fontSize: 20)),
        content: Text(s['aboutBody'], style: AppText.body15(color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AppText.button(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, AppStrings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.ivoryL,
        title: Text(s['resetConfirmTitle'], style: AppText.cardTitle().copyWith(fontSize: 17)),
        content: Text(s['resetConfirmBody'], style: AppText.body15(color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s['cancel'], style: AppText.button(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s['confirm'], style: AppText.button(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(taskRepositoryProvider).resetAll();
      await ref.read(recordRepositoryProvider).resetAll();
    }
  }
}

// ---- Small building blocks ----

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.settingsCard),
        border: Border.all(color: AppColors.ivoryD),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.ivoryD);
}

class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.label,
    this.value,
    this.trailingText,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.body15())),
            if (value != null)
              Text(value!, style: AppText.body15(color: AppColors.inkSoft)),
            if (trailingText != null) ...[
              const SizedBox(width: 10),
              Text(trailingText!, style: AppText.pill(color: AppColors.accent)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body15())),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.ivoryL,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: const BorderSide(color: AppColors.ink),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(child: Text(label, style: AppText.button(color: AppColors.ink))),
        ),
      ),
    );
  }
}
