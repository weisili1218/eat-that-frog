import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/supabase_client.dart';

/// Google *web* client ID — required on iOS/Android to receive an `idToken`
/// that Supabase can verify. Pass with
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=...`.
const _googleWebClientId =
    String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
const _googleIosClientId =
    String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');

/// Emits the current signed-in user (null in local mode / signed out).
final authUserProvider = StreamProvider<User?>((ref) {
  final svc = SupabaseService.instance;
  if (!svc.isAvailable) return Stream<User?>.value(null);
  return svc.client.auth.onAuthStateChange.map((e) => e.session?.user);
});

/// Whether cloud sync is even possible (Supabase configured).
final cloudAvailableProvider = Provider<bool>((ref) {
  return SupabaseService.instance.isAvailable;
});

final authControllerProvider = Provider<AuthController>((ref) => AuthController());

class AuthController {
  SupabaseClient get _client => SupabaseService.instance.client;

  bool get isCloudAvailable => SupabaseService.instance.isAvailable;
  User? get currentUser => SupabaseService.instance.user;

  /// Sign in with Apple (required by App Store for third-party sign-in).
  Future<void> signInWithApple() async {
    _ensureCloud();
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('No identity token from Apple.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> signInWithGoogle() async {
    _ensureCloud();
    final googleSignIn = GoogleSignIn(
      clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
      serverClientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // cancelled
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null) {
      throw const AuthException('No idToken from Google (check web client ID).');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    if (!isCloudAvailable) return;
    await _client.auth.signOut();
  }

  void _ensureCloud() {
    if (!isCloudAvailable) {
      throw const AuthException(
          'Cloud sync is not configured (missing Supabase URL / anon key).');
    }
  }

  String _generateNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = DateTime.now().microsecondsSinceEpoch;
    final buf = StringBuffer();
    var seed = r;
    for (var i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      buf.write(chars[seed % chars.length]);
    }
    return buf.toString();
  }
}
