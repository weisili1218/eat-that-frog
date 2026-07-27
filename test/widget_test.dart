import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eat_that_frog/app.dart';

void main() {
  testWidgets('App shell shows the four tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RootShell()),
      ),
    );
    await tester.pump();

    expect(find.text('今日'), findsWidgets);
    expect(find.text('收集'), findsOneWidget);
    expect(find.text('統計'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });
}
