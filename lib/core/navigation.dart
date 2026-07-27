import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/widgets/tab_bar.dart';

/// The currently selected bottom tab. Pages read this to navigate
/// (e.g. Today's empty-state "go to Inbox" button).
final currentTabProvider = StateProvider<AppTab>((ref) => AppTab.today);
