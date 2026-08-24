import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme_controller.dart';

class WalletActivity {
  final String label;
  final double amount;
  final bool isPositive;
  final DateTime time;

  const WalletActivity({
    required this.label,
    required this.amount,
    required this.isPositive,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'isPositive': isPositive,
        'time': time.toIso8601String(),
      };

  factory WalletActivity.fromJson(Map<String, dynamic> json) => WalletActivity(
        label: json['label'] as String? ?? 'Activity',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        isPositive: json['isPositive'] as bool? ?? true,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Cloud + on-device store for one signed-in account.
/// Every user id gets its own document and local cache.
class UserAccountStore extends ChangeNotifier {
  UserAccountStore._();
  static final UserAccountStore instance = UserAccountStore._();

  static const _legacyDemoKey = 'demo_us100_mt5_v1';
  static const _legacyImageKey = 'profile_image_path';

  String? uid;
  String email = '';
  String displayName = '';
  String username = '';
  String country = 'Pakistan';
  String timezone = '(GMT+5) Pakistan Time';
  String defaultMarket = 'BTC/USDT';
  String defaultOrderType = 'Market';
  String defaultCurrency = 'USDT';
  String plan = 'Demo Pro Plan';
  String chartInterval = '15';
  String chartSymbol = 'US100';
  bool darkMode = true;
  bool twoFAEnabled = false;
  bool biometricEnabled = true;
  bool loginAlerts = true;
  String? profileImagePath;
  final List<WalletActivity> walletActivity = [];

  bool get isBound => uid != null;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final id = uid;
    if (id == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(id);
  }

  String get _cacheKey => 'account_$uid';
  String get _imageKey => 'profile_image_$uid';

  Future<void> bindToCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      resetMemory();
      return;
    }
    uid = user.uid;
    email = user.email ?? '';
    displayName = user.displayName ?? '';
    await _loadLocalFast();
    isDarkMode.value = darkMode;
    notifyListeners();
    unawaited(_syncCloudInBackground());
  }

  Future<void> _loadLocalFast() async {
    var data = await _readLocalCache();
    data ??= await _maybeMigrateLegacy();
    if (data == null) {
      username = displayName.isNotEmpty
          ? displayName.toLowerCase().replaceAll(' ', '_')
          : (email.contains('@') ? email.split('@').first : 'user');
      return;
    }
    _applyMap(data);
    if (username.isEmpty) {
      username = displayName.isNotEmpty
          ? displayName.toLowerCase().replaceAll(' ', '_')
          : (email.contains('@') ? email.split('@').first : 'user');
    }
  }

  Future<void> _syncCloudInBackground() async {
    try {
      final snap = await _doc?.get().timeout(const Duration(seconds: 3));
      if (snap != null && snap.exists) {
        final data = snap.data();
        if (data != null) {
          _applyMap(data);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(data));
          isDarkMode.value = darkMode;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Firestore sync skipped: $e');
    }
  }

  void resetMemory() {
    uid = null;
    email = '';
    displayName = '';
    username = '';
    country = 'Pakistan';
    timezone = '(GMT+5) Pakistan Time';
    defaultMarket = 'BTC/USDT';
    defaultOrderType = 'Market';
    defaultCurrency = 'USDT';
    plan = 'Demo Pro Plan';
    chartInterval = '15';
    chartSymbol = 'US100';
    darkMode = true;
    twoFAEnabled = false;
    biometricEnabled = true;
    loginAlerts = true;
    profileImagePath = null;
    walletActivity.clear();
    notifyListeners();
  }


  void _applyMap(Map<String, dynamic> data) {
    username = data['username'] as String? ?? username;
    country = data['country'] as String? ?? country;
    timezone = data['timezone'] as String? ?? timezone;
    defaultMarket = data['defaultMarket'] as String? ?? defaultMarket;
    defaultOrderType = data['defaultOrderType'] as String? ?? defaultOrderType;
    defaultCurrency = data['defaultCurrency'] as String? ?? defaultCurrency;
    plan = data['plan'] as String? ?? plan;
    chartInterval = data['chartInterval'] as String? ?? chartInterval;
    chartSymbol = data['chartSymbol'] as String? ?? chartSymbol;
    darkMode = data['darkMode'] as bool? ?? darkMode;
    twoFAEnabled = data['twoFAEnabled'] as bool? ?? twoFAEnabled;
    biometricEnabled = data['biometricEnabled'] as bool? ?? biometricEnabled;
    loginAlerts = data['loginAlerts'] as bool? ?? loginAlerts;
    profileImagePath = data['profileImagePath'] as String?;
    walletActivity
      ..clear()
      ..addAll(((data['walletActivity'] as List?) ?? []).map(
        (e) => WalletActivity.fromJson(Map<String, dynamic>.from(e as Map)),
      ));
  }

  Future<Map<String, dynamic>?> _readLocalCache() async {
    if (uid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// First account on this device inherits the old unscoped demo data.
  Future<Map<String, dynamic>?> _maybeMigrateLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyDemoKey);
    final image = prefs.getString(_legacyImageKey);
    if (raw == null && image == null) return null;
    Map<String, dynamic> demo = {};
    if (raw != null) {
      try {
        demo = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {
      'demoBalance': demo['balance'],
      'positions': demo['positions'],
      'trades': demo['trades'],
      if (image != null) 'profileImagePath': image,
    };
  }

  Map<String, dynamic> snapshot({
    required double demoBalance,
    required List<Map<String, dynamic>> positions,
    required List<Map<String, dynamic>> trades,
  }) {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'country': country,
      'timezone': timezone,
      'defaultMarket': defaultMarket,
      'defaultOrderType': defaultOrderType,
      'defaultCurrency': defaultCurrency,
      'plan': plan,
      'chartInterval': chartInterval,
      'chartSymbol': chartSymbol,
      'darkMode': darkMode,
      'twoFAEnabled': twoFAEnabled,
      'biometricEnabled': biometricEnabled,
      'loginAlerts': loginAlerts,
      'profileImagePath': profileImagePath,
      'demoBalance': demoBalance,
      'positions': positions,
      'trades': trades,
      'walletActivity': walletActivity.map((e) => e.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> saveAll({
    double? demoBalance,
    List<Map<String, dynamic>>? positions,
    List<Map<String, dynamic>>? trades,
  }) async {
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final cached = await _readLocalCache() ?? {};
    final data = snapshot(
      demoBalance: demoBalance ?? (cached['demoBalance'] as num?)?.toDouble() ?? 10000,
      positions: positions ??
          ((cached['positions'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
      trades: trades ??
          ((cached['trades'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
    );

    await prefs.setString(_cacheKey, jsonEncode(data));
    if (profileImagePath != null) {
      await prefs.setString(_imageKey, profileImagePath!);
    }

    unawaited(() async {
      try {
        await _doc?.set(data, SetOptions(merge: true)).timeout(
              const Duration(seconds: 4),
            );
      } catch (e) {
        debugPrint('Firestore save failed (data kept on this device): $e');
      }
    }());
    notifyListeners();
  }

  Future<Map<String, dynamic>> demoPayload() async {
    final cached = await _readLocalCache() ?? {};
    return {
      'balance': cached['demoBalance'],
      'positions': cached['positions'],
      'trades': cached['trades'],
    };
  }

  Future<void> setProfileImagePath(String path) async {
    profileImagePath = path;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_imageKey, path);
    }
    await saveAll();
  }

  Future<String?> loadProfileImagePath() async {
    if (uid == null) return null;
    if (profileImagePath != null) return profileImagePath;
    final prefs = await SharedPreferences.getInstance();
    profileImagePath = prefs.getString(_imageKey);
    return profileImagePath;
  }

  void addWalletActivity(WalletActivity activity) {
    walletActivity.insert(0, activity);
    if (walletActivity.length > 50) {
      walletActivity.removeRange(50, walletActivity.length);
    }
  }

  Future<void> deleteCloudData() async {
    if (uid == null) return;
    try {
      await _doc?.delete();
    } catch (e) {
      debugPrint('Could not delete cloud account data: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_imageKey);
  }
}
