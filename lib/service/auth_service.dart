import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'demo_trade_service.dart';
import 'user_account_store.dart';
import 'ai_learning_store.dart';

class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class AuthService {
  static Future<UserCredential?> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await FirebaseAuth.instance
          .signInWithCredential(credential);
      unawaited(_hydrateSession());
      return cred;

    } catch (e) {
      print("Google Login Error: $e");
      return null;
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
      );
    }
  }

  // Logout
  static Future<void> logout() async {
    await DemoTradeService.instance.flushAndReset();
    UserAccountStore.instance.resetMemory();
    AiLearningStore.instance.resetMemory();
    try {
      await GoogleSignIn().signOut();
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