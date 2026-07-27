# Native setup (do after `flutter create .`)

The Dart code is complete, but Sign in with Apple, Google Sign-In, and local
notifications each need native configuration. Do these once the platform folders
exist.

## 0. Generate platform folders + code

```bash
flutter create . --org com.example --project-name eat_that_frog --platforms ios,android
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 1. Supabase credentials

Run with:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

In the Supabase dashboard → Authentication → Providers, enable **Apple** and
**Google** and fill in their client IDs/secrets.

## 2. Sign in with Apple

- **Apple Developer**: enable the *Sign In with Apple* capability for your App ID.
- **Xcode**: Runner target → Signing & Capabilities → **+ Sign in with Apple**.
- Supabase → Auth → Apple: add your Services ID / Team ID / Key.

No client secret is needed in the app — the flow uses the native credential +
nonce (already implemented in `auth_provider.dart`).

## 3. Google Sign-In

- Create OAuth client IDs in Google Cloud Console:
  - an **iOS** client ID,
  - a **Web** client ID (this is the one Supabase verifies).
- iOS: add the iOS client's reversed ID to `ios/Runner/Info.plist` under
  `CFBundleURLTypes`, and drop `GoogleService-Info.plist` into `ios/Runner`.
- Android: add `google-services.json` to `android/app/` and register the SHA-1.
- Supabase → Auth → Google: paste the **Web** client ID + secret.
- Run with the client IDs:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=yyyy.apps.googleusercontent.com
```

## 4. Local notifications

**iOS** — `ios/Runner/Info.plist`: no key required for basic alerts, but for
scheduled notifications while backgrounded add the notification capability in
Xcode. Permission is requested at launch (`requestPermissions`).

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

The app uses **inexact** scheduling (`inexactAllowWhileIdle`) so it does *not*
need the `SCHEDULE_EXACT_ALARM` permission.

## 5. Fonts

Fonts (Fraunces, Inter, Geist Mono, Caveat) are loaded at runtime by
`google_fonts`, so no asset bundling is required. To ship them offline instead,
download the `.ttf` files into `assets/fonts/` and declare them in `pubspec.yaml`.
