import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eat_that_frog/core/constants.dart';
import 'package:eat_that_frog/shared/widgets/tab_bar.dart';

// NOTE: RootShell isn't widget-tested here on purpose — mounting it boots the
// real provider graph (Drift, SharedPreferences, notifications), which needs
// platform channels a plain widget test doesn't have. Shell wiring is covered
// by on-device runs; these tests cover pure UI + logic.

void main() {
  group('tab bar', () {
    Widget wrap(AppTab current, {bool hasInbox = false, bool showFriends = true}) =>
        MaterialApp(
          home: Scaffold(
            body: FrostedTabBar(
              current: current,
              onSelect: (_) {},
              hasInbox: hasInbox,
              showFriends: showFriends,
              strings: AppStrings.zh,
            ),
          ),
        );

    testWidgets('shows the four v4 tabs (settings is not a tab)', (tester) async {
      await tester.pumpWidget(wrap(AppTab.today));
      await tester.pump();

      expect(find.text('今日'), findsOneWidget);
      expect(find.text('收集'), findsOneWidget);
      expect(find.text('統計'), findsOneWidget);
      expect(find.text('好友'), findsOneWidget);
      // Settings moved to the gear overlay in v4.
      expect(find.text('設定'), findsNothing);
    });

    testWidgets('friends tab hides when disabled', (tester) async {
      await tester.pumpWidget(wrap(AppTab.today, showFriends: false));
      await tester.pump();

      expect(find.text('好友'), findsNothing);
      expect(find.text('今日'), findsOneWidget);
    });

    testWidgets('reports the tapped tab', (tester) async {
      AppTab? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FrostedTabBar(
            current: AppTab.today,
            onSelect: (t) => tapped = t,
            hasInbox: false,
            strings: AppStrings.zh,
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('統計'));
      expect(tapped, AppTab.stats);
    });
  });
}
