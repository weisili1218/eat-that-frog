import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/navigation.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../auth/auth_page.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';

/// Full-screen Settings overlay (opened via the gear icon).
class SettingsOverlay extends ConsumerWidget {
  const SettingsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final cloud = ref.watch(cloudAvailableProvider);

    void close() => ref.read(settingsOpenProvider.notifier).state = false;

    return Material(
      color: AppColors.ivoryL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['prefsMono'], style: AppText.mono()),
                      const SizedBox(height: 6),
                      Text(s['settingsTitle'], style: AppText.title()),
                    ],
                  ),
                ),
                _CircleIcon(icon: Icons.close, onTap: close),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
              children: [
                // Account / sync
                _Card(children: [
                  _Tappable(
                    label: user != null
                        ? (user.email ?? user.userMetadata?['name']?.toString() ?? '已登入')
                        : (cloud ? s['loginSync'] : s['localMode']),
                    value: user != null ? s['syncedAt'] : null,
                    trailingText: user != null ? s['signOut'] : null,
                    onTap: () async {
                      if (user != null) {
                        await ref.read(authControllerProvider).signOut();
                      } else {
                        await showAuthSheet(context);
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 16),

                // Language
                _Card(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(s['langLabel'], style: AppText.body15())),
                        _LangChip(
                          label: '中文',
                          active: settings.language == AppLocale.zh,
                          onTap: () => ref.read(settingsProvider.notifier).setLanguage(AppLocale.zh),
                        ),
                        const SizedBox(width: 6),
                        _LangChip(
                          label: 'EN',
                          active: settings.language == AppLocale.en,
                          onTap: () => ref.read(settingsProvider.notifier).setLanguage(AppLocale.en),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Reminders
                _Card(children: [
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
                    value: settings.weeklyEnabled ? '週日 ${formatTime(settings.weeklyReview)}' : '關閉',
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
                    onChanged: (v) => ref.read(settingsProvider.notifier).setWeeklyEnabled(v),
                  ),
                  const _Divider(),
                  _SwitchRow(
                    label: s['monthlyLeave'],
                    value: settings.leaveEnabled,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setLeaveEnabled(v),
                  ),
                ]),
                const SizedBox(height: 16),

                // About
                _Card(children: [
                  _Tappable(label: s['about'], onTap: () => _showAbout(context, s)),
                ]),
                const SizedBox(height: 16),

                _OutlineButton(
                  label: s['simulateDayBtn'],
                  subtle: true,
                  onTap: () => ref.read(taskRepositoryProvider).simulateNextDay(),
                ),
                const SizedBox(height: 10),
                _OutlineButton(
                  label: s['resetBtn'],
                  onTap: () => _confirmReset(context, ref, s),
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
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.light(primary: AppColors.accent)),
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
      await ref.read(completionRepositoryProvider).resetAll();
    }
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ivoryD),
          ),
          child: Icon(icon, size: 14, color: AppColors.ink),
        ),
      );
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.ink),
          ),
          child: Text(label,
              style: AppText.pill(color: active ? AppColors.ivoryL : AppColors.ink)
                  .copyWith(fontSize: 12.5)),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.settingsCard),
          border: Border.all(color: AppColors.ivoryD),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.ivoryD);
}

class _Tappable extends StatelessWidget {
  const _Tappable({required this.label, this.value, this.trailingText, required this.onTap});
  final String label;
  final String? value;
  final String? trailingText;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.body15())),
              if (value != null) Text(value!, style: AppText.body15(color: AppColors.inkSoft)),
              if (trailingText != null) ...[
                const SizedBox(width: 10),
                Text(trailingText!, style: AppText.pill(color: AppColors.accent)),
              ],
            ],
          ),
        ),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.body15())),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.ivoryL,
              activeTrackColor: AppColors.accent,
            ),
          ],
        ),
      );
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap, this.subtle = false});
  final String label;
  final VoidCallback onTap;
  final bool subtle;
  @override
  Widget build(BuildContext context) {
    final color = subtle ? AppColors.ivoryD : AppColors.ink;
    final textColor = subtle ? AppColors.inkSoft : AppColors.ink;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: color),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(child: Text(label, style: AppText.button(color: textColor))),
        ),
      ),
    );
  }
}
