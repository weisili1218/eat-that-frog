import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Entrance animation matching the design's `fadeUp` keyframe:
/// opacity 0→1, translateY 16px→0, 500ms, cubic(0.2,0.7,0.2,1.0).
///
/// Wrap any widget; pass [index] for a staggered list (55ms per item by
/// default, matching the 50–60ms spec).
class FadeUp extends StatefulWidget {
  const FadeUp({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
  });

  final Widget child;
  final int index;
  final Duration delay;

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.fadeUpDuration,
  );
  late final Animation<double> _curved =
      CurvedAnimation(parent: _c, curve: AppMotion.fadeUpCurve);

  @override
  void initState() {
    super.initState();
    final total = widget.delay + AppMotion.staggerStep * widget.index;
    if (total == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(total, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        return Opacity(
          opacity: _curved.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - _curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
