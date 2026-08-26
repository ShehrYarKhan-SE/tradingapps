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

class LoginRecord {
  final String device;
  final DateTime time;

  const LoginRecord({required this.device, required this.time});

  Map<String, dynamic> toJson() => {
        'device': device,
        'time': time.toIso8601String(),
      };

  factory LoginRecord.fromJson(Map<String, dynamic> json) => LoginRecord(
        device: json['device'] as String? ?? 'Unknown device',
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      );
}

class LinkedDevice {
  final String id;
  final String name;
  final DateTime lastActive;

  const LinkedDevice({
    required this.id,
    required this.name,
    required this.lastActive,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lastActive': lastActive.toIso8601String(),
      };

  factory LinkedDevice.fromJson(Map<String, dynamic> json) => LinkedDevice(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Device',
        lastActive:
            DateTime.tryParse(json['lastActive'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Cloud source of truth for one signed-in account (`users/{uid}`).
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
  String phone = '';
  bool darkMode = true;
  bool twoFAEnabled = false;
  bool biometricEnabled = true;
  bool loginAlerts = true;
  String? profileImagePath;
  String? profileImageUrl;
  final List<WalletActivity> walletActivity = [];
  final List<LoginRecord> loginHistory = [];
  final List<LinkedDevice> devices = [];
  final List<Map<String, dynamic>> supportTickets = [];

  double demoBalance = 10000;
  List<Map<String, dynamic>> demoPositions = [];
  List<Map<String, dynamic>> demoTrades = [];
  Map<String, dynamic> learning = {};
  Map<String, dynamic> chartDrawings = {};
  String? updatedAtIso;

  bool get isBound => uid != null;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final id = uid;
    if (id == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(id);
  }

  String get _cacheKey => 'account_$uid';
  String get _imageKey => 'profile_image_$uid';

  Future<void>? _bindInFlight;
  Future<void> _saveChain = Future.value();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _cloudSub;
  bool _saving = false;
  bool _applyingRemote = false;

  Future<void> bindToCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _stopCloud();
      resetMemory();
      return;
    }
    if (_bindInFlight != null && uid == user.uid) {
      await _bindInFlight;
      return;
    }
    final future = _bind(user);
    _bindInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_bindInFlight, future)) _bindInFlight = null;
    }
  }

  Future<void> _bind(User user) async {
    uid = user.uid;
    email = user.email ?? '';
    if ((user.displayName ?? '').isNotEmpty) {
      displayName = user.displayName!;
    }
    await _loadLocalFast();
    isDarkMode.value = darkMode;
    notifyListeners();
    await _syncCloud();
    _listenCloud();
    await recordThisDevice();
    isDarkMode.value = darkMode;
    notifyListeners();
  }

  Future<void> _loadLocalFast() async {
    var data = await _readLocalCache();
    data ??= await _maybeMigrateLegacy();
    if (data == null) {
      _ensureUsername();
      return;
    }
    _applyMap(data);
    _ensureUsername();
  }

  void _ensureUsername() {
    if (username.isNotEmpty) return;
    username = displayName.isNotEmpty
        ? displayName.toLowerCase().replaceAll(' ', '_')
        : (email.contains('@') ? email.split('@').first : 'user');
  }

  Future<void> _syncCloud() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      final snap = await doc.get().timeout(const Duration(seconds: 20));
      final cloud = snap.data();
      final local = await _readLocalCache();
      final winner = _preferNewer(local, cloud);
      if (winner != null) {
        _applyMap(winner);
        await _writeLocal(winner);
      }
      final shouldUpload = !snap.exists ||
          (winner != null &&
              local != null &&
              identical(winner, local) &&
              !_sameStamp(local, cloud));
      if (shouldUpload || !snap.exists) {
        final payload = _currentSnapshot();
        _applyMap(payload);
        await _writeLocal(payload);
        await _writeCloud(payload);
      }
    } catch (e) {
      debugPrint('Firestore sync skipped: $e');
    }
  }

  void _listenCloud() {
    final doc = _doc;
    if (doc == null) return;
    _cloudSub?.cancel();
    _cloudSub = doc.snapshots().listen((snap) {
      if (_saving || _applyingRemote) return;
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      if (data['updatedAt'] == updatedAtIso) return;
      final remoteAt = DateTime.tryParse(data['updatedAt'] as String? ?? '');
      final localAt = DateTime.tryParse(updatedAtIso ?? '');
      if (remoteAt != null &&
          localAt != null &&
          !remoteAt.isAfter(localAt)) {
        return;
      }
      _applyingRemote = true;
      try {
        _applyMap(data);
        unawaited(_writeLocal(data));
        isDarkMode.value = darkMode;
        notifyListeners();
      } finally {
        _applyingRemote = false;
      }
    }, onError: (e) {
      debugPrint('Firestore listen skipped: $e');
    });
  }

  Future<void> _stopCloud() async {
    await _cloudSub?.cancel();
    _cloudSub = null;
  }

  void resetMemory() {
    unawaited(_stopCloud());
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
    phone = '';
    darkMode = true;
    twoFAEnabled = false;
    biometricEnabled = true;
    loginAlerts = true;
    profileImagePath = null;
    profileImageUrl = null;
    walletActivity.clear();
    loginHistory.clear();
    devices.clear();
    supportTickets.clear();
    demoBalance = 10000;
    demoPositions = [];
    demoTrades = [];
    learning = {};
    chartDrawings = {};
    updatedAtIso = null;
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
    phone = data['phone'] as String? ?? phone;
    darkMode = data['darkMode'] as bool? ?? darkMode;
    twoFAEnabled = data['twoFAEnabled'] as bool? ?? twoFAEnabled;
    biometricEnabled = data['biometricEnabled'] as bool? ?? biometricEnabled;
    loginAlerts = data['loginAlerts'] as bool? ?? loginAlerts;
    profileImagePath = data['profileImagePath'] as String? ?? profileImagePath;
    profileImageUrl = data['profileImageUrl'] as String? ?? profileImageUrl;
    walletActivity
      ..clear()
      ..addAll(_mapList(data['walletActivity']).map(WalletActivity.fromJson));
    loginHistory
      ..clear()
      ..addAll(_mapList(data['loginHistory']).map(LoginRecord.fromJson));
    devices
      ..clear()
      ..addAll(_mapList(data['devices']).map(LinkedDevice.fromJson));
    supportTickets
      ..clear()
      ..addAll(_mapList(data['supportTickets']));
    demoBalance = (data['demoBalance'] as num?)?.toDouble() ?? demoBalance;
    demoPositions = _mapList(data['positions']);
    demoTrades = _mapList(data['trades']);
    final rawLearning = data['learning'];
    if (rawLearning is Map) {
      learning = Map<String, dynamic>.from(rawLearning);
    }
    final rawDrawings = data['chartDrawings'];
    if (rawDrawings is Map) {
      chartDrawings = Map<String, dynamic>.from(rawDrawings);
    }
    updatedAtIso = data['updatedAt'] as String? ?? updatedAtIso;
    if ((data['email'] as String?)?.isNotEmpty == true) {
      email = data['email'] as String;
    }
    if ((data['displayName'] as String?)?.isNotEmpty == true) {
      displayName = data['displayName'] as String;
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? _preferNewer(
    Map<String, dynamic>? local,
    Map<String, dynamic>? cloud,
  ) {
    if (cloud == null || cloud.isEmpty) return local;
    if (local == null || local.isEmpty) return cloud;
    final lt = DateTime.tryParse(local['updatedAt'] as String? ?? '');
    final ct = DateTime.tryParse(cloud['updatedAt'] as String? ?? '');
    if (lt != null && ct != null) {
      if (lt.isAfter(ct)) return local;
      if (ct.isAfter(lt)) return cloud;
    }
    return _activityScore(cloud) >= _activityScore(local) ? cloud : local;
  }

  int _activityScore(Map<String, dynamic> data) {
    final trades = (data['trades'] as List?)?.length ?? 0;
    final positions = (data['positions'] as List?)?.length ?? 0;
    final wallet = (data['walletActivity'] as List?)?.length ?? 0;
    final completed =
        ((data['learning'] as Map?)?['completed'] as List?)?.length ?? 0;
    final bal = (data['demoBalance'] as num?)?.toDouble() ?? 10000;
    return trades * 10 +
        positions * 5 +
        wallet * 2 +
        completed * 3 +
        (bal != 10000 ? 1 : 0);
  }

  bool _sameStamp(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null || b == null) return false;
    return a['updatedAt'] != null && a['updatedAt'] == b['updatedAt'];
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

  Future<void> _writeLocal(Map<String, dynamic> data) async {
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
    final path = data['profileImagePath'] as String?;
    if (path != null) {
      await prefs.setString(_imageKey, path);
    }
  }

  Future<void> _writeCloud(Map<String, dynamic> data) async {
    final doc = _doc;
    if (doc == null) return;
    final payload = Map<String, dynamic>.from(data)
      ..removeWhere((k, v) => v == null);
    await doc.set(payload, SetOptions(merge: true));
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
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _currentSnapshot() {
    return snapshot(
      demoBalance: demoBalance,
      positions: demoPositions,
      trades: demoTrades,
    );
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
      'phone': phone,
      'darkMode': darkMode,
      'twoFAEnabled': twoFAEnabled,
      'biometricEnabled': biometricEnabled,
      'loginAlerts': loginAlerts,
      'profileImagePath': profileImagePath,
      'profileImageUrl': profileImageUrl,
      'demoBalance': demoBalance,
      'positions': positions,
      'trades': trades,
      'walletActivity': walletActivity.map((e) => e.toJson()).toList(),
      'loginHistory': loginHistory.map((e) => e.toJson()).toList(),
      'devices': devices.map((e) => e.toJson()).toList(),
      'supportTickets': supportTickets,
      'learning': learning,
      'chartDrawings': chartDrawings,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> saveAll({
    double? demoBalance,
    List<Map<String, dynamic>>? positions,
    List<Map<String, dynamic>>? trades,
  }) {
    _saveChain = _saveChain.then((_) {
      return _saveNow(
        demoBalance: demoBalance,
        positions: positions,
        trades: trades,
      );
    }).catchError((e) {
      debugPrint('Firestore save failed: $e');
    });
    return _saveChain;
  }

  Future<void> _saveNow({
    double? demoBalance,
    List<Map<String, dynamic>>? positions,
    List<Map<String, dynamic>>? trades,
  }) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    this.demoBalance = demoBalance ?? this.demoBalance;
    if (positions != null) demoPositions = positions;
    if (trades != null) demoTrades = trades;
    final data = _currentSnapshot();
    _applyMap(data);
    _saving = true;
    try {
      await _writeLocal(data);
      try {
        await _writeCloud(data);
      } catch (e) {
        debugPrint('Firestore save failed (data kept on this device): $e');
      }
    } finally {
      _saving = false;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> demoPayload() async {
    return {
      'balance': demoBalance,
      'positions': demoPositions,
      'trades': demoTrades,
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

  static String deviceLabel() {
    if (kIsWeb) return 'Web browser';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android phone';
      case TargetPlatform.iOS:
        return 'iPhone';
      case TargetPlatform.windows:
        return 'Windows PC';
      case TargetPlatform.macOS:
        return 'Mac';
      default:
        return 'This device';
    }
  }

  Future<String> _localDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null || id.isEmpty) {
      id = 'd_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', id);
    }
    return id;
  }

  Future<void> recordThisDevice() async {
    final id = await _localDeviceId();
    final name = deviceLabel();
    final now = DateTime.now();
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      devices[idx] = LinkedDevice(id: id, name: name, lastActive: now);
    } else {
      devices.insert(0, LinkedDevice(id: id, name: name, lastActive: now));
    }
    final last = loginHistory.isEmpty ? null : loginHistory.first;
    if (last == null || now.difference(last.time).inMinutes >= 10) {
      loginHistory.insert(0, LoginRecord(device: name, time: now));
      if (loginHistory.length > 30) {
        loginHistory.removeRange(30, loginHistory.length);
      }
    }
    if (devices.length > 12) devices.removeRange(12, devices.length);
    await saveAll();
  }

  Future<void> removeOtherDevices() async {
    final id = await _localDeviceId();
    devices.removeWhere((d) => d.id != id);
    await saveAll();
  }

  Future<void> addSupportTicket(String subject, String message) async {
    supportTickets.insert(0, {
      'subject': subject,
      'message': message,
      'time': DateTime.now().toIso8601String(),
      'status': 'open',
    });
    if (supportTickets.length > 20) {
      supportTickets.removeRange(20, supportTickets.length);
    }
    await saveAll();
  }

  Future<void> deleteCloudData() async {
    await _stopCloud();
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
