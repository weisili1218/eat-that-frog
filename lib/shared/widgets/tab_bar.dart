import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

enum AppTab { today, inbox, stats }

/// Bottom tab bar (3 tabs) with frosted-glass effect. Settings is opened via a
/// gear icon, not a tab.
class FrostedTabBar extends StatelessWidget {
  const FrostedTabBar({
    super.key,
    required this.current,
    required this.onSelect,
    required this.hasInbox,
    this.strings = AppStrings.zh,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelect;
  final bool hasInbox;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
          decoration: const BoxDecoration(
            color: Color(0xEBFAF8F3),
            border: Border(top: BorderSide(color: AppColors.ivoryD)),
          ),
          child: Row(
            children: [
              _TabItem(
                label: strings['todayTab'],
                active: current == AppTab.today,
                onTap: () => onSelect(AppTab.today),
                icon: _todayIcon,
              ),
              _TabItem(
                label: strings['inboxTab'],
                active: current == AppTab.inbox,
                onTap: () => onSelect(AppTab.inbox),
                icon: _inboxIcon,
                showDot: hasInbox,
              ),
              _TabItem(
                label: strings['statsTab'],
                active: current == AppTab.stats,
                onTap: () => onSelect(AppTab.stats),
                icon: _statsIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _todayIcon(Color c) =>
      CustomPaint(size: const Size(21, 21), painter: _TodayPainter(c));
  static Widget _inboxIcon(Color c) =>
      CustomPaint(size: const Size(21, 21), painter: _InboxPainter(c));
  static Widget _statsIcon(Color c) =>
      CustomPaint(size: const Size(21, 21), painter: _StatsPainter(c));
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
    required this.icon,
    this.showDot = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget Function(Color) icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.cloud;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon(color),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppText.mono(size: 9.5, color: color, letterSpacing: 0.04),
                  ),
                ],
              ),
              if (showDot)
                const Positioned(top: 0, right: 22, child: _Dot()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      );
}

class _TodayPainter extends CustomPainter {
  _TodayPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 20;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2 * s, 2 * s, 16 * s, 16 * s),
        Radius.circular(5 * s),
      ),
      stroke,
    );
    canvas.drawCircle(Offset(10 * s, 10 * s), 2.6 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TodayPainter old) => old.color != color;
}

class _InboxPainter extends CustomPainter {
  _InboxPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 20;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    final top = Path()
      ..moveTo(3 * s, 4 * s)
      ..lineTo(17 * s, 4 * s)
      ..lineTo(15 * s, 12 * s)
      ..lineTo(5 * s, 12 * s)
      ..close();
    canvas.drawPath(top, stroke);
    final bottom = Path()
      ..moveTo(5 * s, 12 * s)
      ..lineTo(5 * s, 14 * s)
      ..arcToPoint(Offset(6 * s, 15 * s), radius: Radius.circular(1 * s))
      ..lineTo(14 * s, 15 * s)
      ..arcToPoint(Offset(15 * s, 14 * s), radius: Radius.circular(1 * s))
      ..lineTo(15 * s, 12 * s);
    canvas.drawPath(bottom, stroke);
  }

  @override
  bool shouldRepaint(covariant _InboxPainter old) => old.color != color;
}

class _StatsPainter extends CustomPainter {
  _StatsPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 20;
    final fill = Paint()..color = color;
    void bar(double x, double y, double h) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * s, y * s, 3.5 * s, h * s),
          Radius.circular(1 * s),
        ),
        fill,
      );
    }

    bar(3, 10, 7);
    bar(8.3, 5, 12);
    bar(13.5, 8, 9);
  }

  @override
  bool shouldRepaint(covariant _StatsPainter old) => old.color != color;
}
