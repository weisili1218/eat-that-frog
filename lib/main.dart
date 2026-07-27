import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme.dart';
import 'data/notifications/notification_service.dart';
import 'data/remote/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase only when configured. Until then the app runs fully
  // in local (Drift) mode — see [SupabaseConfig].
  await SupabaseService.instance.initIfConfigured();

  // Local notifications (daily frog reminder + weekly review).
  await NotificationService.instance.init();
  unawaited(NotificationService.instance.requestPermissions());

  runApp(const ProviderScope(child: EatThatFrogApp()));
}

class EatThatFrogApp extends StatelessWidget {
  const EatThatFrogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '先吃掉那隻青蛙',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootShell(),
    );
  }
}
