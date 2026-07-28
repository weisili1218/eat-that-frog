import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/widgets/tab_bar.dart';

/// The currently selected bottom tab (today / inbox / stats).
final currentTabProvider = StateProvider<AppTab>((ref) => AppTab.today);

/// Whether the full-screen Settings overlay is open (opened via the gear icon).
final settingsOpenProvider = StateProvider<bool>((ref) => false);

/// The task currently in focus mode (dims all others), or null.
final focusedTaskProvider = StateProvider<String?>((ref) => null);
