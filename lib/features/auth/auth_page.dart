import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

/// Shows the sign-in options as a modal bottom sheet.
Future<void> showAuthSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.ivoryL,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AuthSheet(),
  );
}

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet();

  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const s = AppStrings.zh;
    final auth = ref.read(authControllerProvider);
    final cloud = ref.watch(cloudAvailableProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.ivoryD,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(s['loginSync'], style: AppText.title().copyWith(fontSize: 26)),
          const SizedBox(height: 16),
          if (!cloud)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.ivoryM,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '尚未設定 Supabase，目前為本地模式。填入 SUPABASE_URL / anon key 後即可雲端同步。',
                style: AppText.body15(color: AppColors.inkSoft),
              ),
            )
          else ...[
            _AuthButton(
              label: s['signInApple'],
              icon: Icons.apple,
              filled: true,
              onTap: _busy ? null : () => _run(auth.signInWithApple),
            ),
            const SizedBox(height: 10),
            _AuthButton(
              label: s['signInGoogle'],
              icon: Icons.g_mobiledata_rounded,
              filled: false,
              onTap: _busy ? null : () => _run(auth.signInWithGoogle),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppText.body15(color: AppColors.accent)),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.ivoryL : AppColors.ink;
    return Material(
      color: filled ? AppColors.ink : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.ivoryD),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 8),
              Text(label, style: AppText.button(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
