import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A brief, satisfying checkmark "pop" overlay played when a frog is marked
/// done. Drive it via a [DoneBurstController].
class DoneBurst extends StatefulWidget {
  const DoneBurst({super.key, required this.controller, required this.child});

  final DoneBurstController controller;
  final Widget child;

  @override
  State<DoneBurst> createState() => _DoneBurstState();
}

class DoneBurstController extends ChangeNotifier {
  void play() => notifyListeners();
}

class _DoneBurstState extends State<DoneBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlay);
  }

  void _onPlay() => _c.forward(from: 0);

  @override
  void dispose() {
    widget.controller.removeListener(_onPlay);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (_c.value == 0 || _c.value == 1) {
              return const SizedBox.shrink();
            }
            final scale = Curves.easeOutBack.transform(_c.value.clamp(0, 1));
            final opacity = 1 - Curves.easeIn.transform(
              ((_c.value - 0.6) / 0.4).clamp(0, 1),
            );
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.4 + scale * 0.9,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.ivoryL, size: 38),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
