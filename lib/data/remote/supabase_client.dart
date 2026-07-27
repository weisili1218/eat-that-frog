import 'package:supabase_flutter/supabase_flutter.dart';

/// Fill these in after creating your Supabase project (Step 2/5).
/// Leave them empty to run the app in local-only mode.
///
/// Prefer passing them at build time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Thin wrapper around the Supabase singleton so the rest of the app can stay
/// agnostic about whether cloud sync is available.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isAvailable => _initialized && SupabaseConfig.isConfigured;

  Future<void> initIfConfigured() async {
    if (!SupabaseConfig.isConfigured || _initialized) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
  }

  SupabaseClient get client => Supabase.instance.client;

  Session? get session => isAvailable ? client.auth.currentSession : null;
  User? get user => isAvailable ? client.auth.currentUser : null;
  bool get isSignedIn => session != null;
}
