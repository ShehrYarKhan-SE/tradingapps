import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'demo_trade_service.dart';
import 'user_account_store.dart';
import 'ai_learning_store.dart';

class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final String? code;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.code,
  });
}

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  static Future<AuthResult> googleLogin() async {
    try {
      final UserCredential cred;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        cred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return AuthResult(success: false, message: '');
        }
        final googleAuth = await googleUser.authentication;
        cred = await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
        );
      }
      unawaited(_hydrateSession());
      return AuthResult(
        success: true,
        message: 'Login Successful',
        user: cred.user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: e.message ?? 'Google sign-in failed',
      );
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('sign_in_canceled') || raw.contains('popup_closed')) {
        return AuthResult(success: false, message: '');
      }
      if (raw.contains('ApiException: 10') || raw.contains('DEVELOPER_ERROR')) {
        return AuthResult(
          success: false,
          message: 'Google sign-in is not configured for this Android build yet.',
        );
      }
      return AuthResult(success: false, message: 'Google sign-in failed');
    }
  }

  static Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(
        success: true,
        message: 'Reset link sent to ${email.trim()}',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: e.message ?? 'Could not send reset email',
      );
    }
  }
  static Future<UserCredential?> facebookLogin() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        return null;
      }

      final OAuthCredential credential =
      FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final cred = await FirebaseAuth.instance
          .signInWithCredential(credential);
      unawaited(_hydrateSession());
      return cred;
    } catch (e) {
      print("Facebook Login Error: $e");
      return null;
    }
  }
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register
  static Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await result.user!.updateDisplayName(username);
      unawaited(_hydrateSession(username: username.trim()));

      return AuthResult(
        success: true,
        message: "Registration Successful",
        user: result.user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: e.message ?? "Registration Failed",
      );
    }
  }

  // Login
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      unawaited(_hydrateSession());

      return AuthResult(
        success: true,
        message: "Login Successful",
        user: result.user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: e.message ?? "Login Failed",
        code: e.code,
      );
    }
  }

  // Logout
  static Future<void> logout() async {
    await DemoTradeService.instance.flushAndReset();
    UserAccountStore.instance.resetMemory();
    AiLearningStore.instance.resetMemory();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await _auth.signOut();
  }

  static Future<void> deleteAccount() async {
    await UserAccountStore.instance.deleteCloudData();
    DemoTradeService.instance.resetMemory();
    UserAccountStore.instance.resetMemory();
    AiLearningStore.instance.resetMemory();
    await FirebaseAuth.instance.currentUser?.delete();
  }

  static Future<void> _hydrateSession({String? username}) async {
    await UserAccountStore.instance.bindToCurrentUser();
    if (username != null && username.isNotEmpty) {
      UserAccountStore.instance.username = username;
      UserAccountStore.instance.displayName = username;
      await UserAccountStore.instance.saveAll();
    }
    await DemoTradeService.instance.init();
    await AiLearningStore.instance.bind();
  }
}