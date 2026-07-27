# 先吃掉那隻青蛙 × GTD

A Flutter productivity app combining **Eat the Frog** + a **GTD collect system** + **streak tracking**. iOS-first, Android-compatible. Offline-capable with optional Supabase sync.

## Stack
Flutter · Riverpod · Drift (SQLite) · Supabase · fl_chart · Google Fonts

## First-time setup

Flutter is **not yet installed** on this machine. Once installed:

```bash
# 1. Install Flutter — https://docs.flutter.dev/get-started/install/macos
# 2. From this directory, generate the iOS/Android platform folders:
flutter create . --org com.example --project-name eat_that_frog --platforms ios,android

# 3. Fetch dependencies
flutter pub get

# 4. Generate Drift + Riverpod code
dart run build_runner build --delete-conflicting-outputs

# 5. Run (local mode works with no backend)
flutter run
```

> `flutter create .` only *adds* the missing `ios/`, `android/`, etc. It will not
> overwrite the existing `lib/` or `pubspec.yaml`.

## Supabase (optional cloud sync)

1. Create a project at https://supabase.com
2. Run the SQL in [`supabase/schema.sql`](supabase/schema.sql) in the SQL Editor.
3. Provide credentials at run time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Without these, the app runs fully offline using the local Drift database.

## Project structure
See the `lib/` tree — `core/` (theme, constants, router), `data/` (local/remote/repositories),
`features/` (today, inbox, stats, settings, auth), `shared/` (widgets, animations).

## Design tokens
All colours, type styles, radii, and motion live in [`lib/core/theme.dart`](lib/core/theme.dart).
Do not hard-code these values elsewhere.
