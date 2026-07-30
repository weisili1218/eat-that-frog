# iOS / TestFlight 交接指南

給有 **完整 Xcode + 付費 Apple Developer 帳號** 的人。這個 repo 是 Flutter app「先吃掉那隻青蛙 × GTD」（Android + iOS 都有），後端 Supabase 已架好。照著做即可 build 並上 TestFlight。

---

## 0. 前置

- macOS + **完整 Xcode**（App Store）
- Flutter SDK（stable）：`flutter --version`
- CocoaPods：`brew install cocoapods`
- 你的 **付費 Apple Developer team**

## 1. Clone + 初始化

```bash
git clone https://github.com/weisili1218/eat-that-frog.git
cd eat-that-frog
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # ⚠️ 產生 Drift 的 *.g.dart，不跑會編不過
cd ios && pod install && cd ..
```

> `*.g.dart` 與 `pubspec.lock` 有被 gitignore，所以 clone 後**一定要** `pub get` + `build_runner`。

## 2. 後端金鑰（build 時用 `--dart-define` 傳）

這些都是**可公開的前端金鑰**（Supabase publishable key + 公開 client id，資料由 RLS 保護，內嵌安全）：

```
SUPABASE_URL=https://mcfizcyidpikagfgkflr.supabase.co
SUPABASE_ANON_KEY=sb_publishable_xeOOhf2MYF4vKwQOkbfDUg_jaP3RJis
GOOGLE_WEB_CLIENT_ID=42495796107-5vdjh60k38vr0p7auar7pppiv24raed4.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=<見第 4 步，你要自己建一個>
```

## 3. Xcode 簽章

Xcode 開 `ios/Runner.xcworkspace` → Runner → **Signing & Capabilities**：

1. **Bundle Identifier**：改成你 team 的唯一 id，例如 `com.yourname.eatthatfrog`。
   ⚠️ `com.example.*` Apple 不給上架，一定要換。
2. **Team**：選你的付費 team，勾 **Automatically manage signing**。

## 4. Google 登入（iOS）

1. Google Cloud Console（同一個專案）→ Credentials → **Create OAuth client → iOS** → 填你上面設的 Bundle ID → 建立後拿到 **iOS client id** 和 **reversed client id**（`com.googleusercontent.apps.xxxx`）。
2. `ios/Runner/Info.plist` 加一段 URL scheme（把 reversed client id 貼進去）：

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

3. build 時帶 `--dart-define=GOOGLE_IOS_CLIENT_ID=<iOS client id>`。

## 5. Sign in with Apple（App Store 有 Google 登入就強制要）

- Xcode → Signing & Capabilities → **+ Capability → Sign in with Apple**。
- Supabase → Authentication → Providers → **Apple** → Enable，把你的 **Bundle ID** 加進 authorized client ids（app 用的是原生 ID-token 流程，程式碼已寫好，見 `lib/features/auth/auth_provider.dart`）。

## 6. Build + 上 TestFlight

**方式 A — 命令列出 ipa：**
```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://mcfizcyidpikagfgkflr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xeOOhf2MYF4vKwQOkbfDUg_jaP3RJis \
  --dart-define=GOOGLE_WEB_CLIENT_ID=42495796107-5vdjh60k38vr0p7auar7pppiv24raed4.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<你的 iOS client id>
```
產物：`build/ios/ipa/*.ipa` → 用 **Transporter**（App Store 免費 app）上傳。

**方式 B — Xcode GUI：** Product → Archive → Distribute App → App Store Connect → Upload。
（dart-define 可寫進 scheme 的 Arguments，或用方式 A 出 ipa 再拖進 Transporter。）

## 7. App Store Connect → TestFlight

1. 建 app 紀錄（用第 3 步的 Bundle ID）。
2. **TestFlight** 分頁 → 等 build 處理完（幾分鐘）：
   - **內部測試者**（team 成員，≤100 人）：不用審核，最快，適合先自己 + 幾個親友。
   - **外部測試者**：需一次輕量 Beta App Review（通常一天內）。
3. 加測試者 email → 他們收到邀請、裝 **TestFlight** app 安裝。

---

## 已知事項（給接手的人參考）
- Beta 1 只驗證單人核心迴圈 + 陪伴社交層。
- **messages 群聊同步**目前是 realtime insert-only（reactions 用 UPDATE），Beta 1→2 過渡會改成獨立的 insert-only reactions 表。**不影響 Beta 1 測試。**
- 排程選青蛙目前是「最適合當前精力」，Beta 1 觀察是否造成困惑（原始精神是「最難/最重要」）。
- 資料庫 schema（v1–v4）已在 Supabase 跑好，不用再跑。
