import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoPosition {
  final String id;
  final String symbol;
  final String side; // BUY or SELL
  final double lots;
  final double openPrice;
  final DateTime time;

  const DemoPosition({
    required this.id,
    required this.symbol,
    required this.side,
    required this.lots,
    required this.openPrice,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side,
        'lots': lots,
        'openPrice': openPrice,
        'time': time.toIso8601String(),
      };

  factory DemoPosition.fromJson(Map<String, dynamic> json) => DemoPosition(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        side: json['side'] as String,
        lots: (json['lots'] as num).toDouble(),
        openPrice: (json['openPrice'] as num).toDouble(),
        time: DateTime.parse(json['time'] as String),
      );

  double pnl(double bid, double ask) {
    final exit = side == 'BUY' ? bid : ask;
    final delta = side == 'BUY' ? exit - openPrice : openPrice - exit;
    return delta * lots * pointValue;
  }

  static const double pointValue = 10;
}

class DemoTrade {
  final String id;
  final String symbol;
  final String side;
  final double lots;
  final double openPrice;
  final double closePrice;
  final double pnl;
  final DateTime time;
  final DateTime closeTime;

  const DemoTrade({
    required this.id,
    required this.symbol,
    required this.side,
    required this.lots,
    required this.openPrice,
    required this.closePrice,
    required this.pnl,
    required this.time,
    required this.closeTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side,
        'lots': lots,
        'openPrice': openPrice,
        'closePrice': closePrice,
        'pnl': pnl,
        'time': time.toIso8601String(),
        'closeTime': closeTime.toIso8601String(),
      };

  factory DemoTrade.fromJson(Map<String, dynamic> json) => DemoTrade(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        side: json['side'] as String,
        lots: (json['lots'] as num).toDouble(),
        openPrice: (json['openPrice'] as num).toDouble(),
        closePrice: (json['closePrice'] as num).toDouble(),
        pnl: (json['pnl'] as num).toDouble(),
        time: DateTime.parse(json['time'] as String),
        closeTime: DateTime.parse(
          (json['closeTime'] as String?) ?? json['time'] as String,
        ),
      );
}

/// Paper US100 account. Orders are local only and persisted on device.
class DemoTradeService extends ChangeNotifier {
  DemoTradeService._();
  static final DemoTradeService instance = DemoTradeService._();

  static const double startingBalance = 10000;
  static const String symbol = 'US100';
  static const _prefsKey = 'demo_us100_mt5_v1';

  bool _ready = false;
  double balance = startingBalance;
  final List<DemoPosition> positions = [];
  final List<DemoTrade> trades = [];

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        balance = (map['balance'] as num?)?.toDouble() ?? startingBalance;
        positions
          ..clear()
          ..addAll(((map['positions'] as List?) ?? []).map(
            (e) => DemoPosition.fromJson(e as Map<String, dynamic>),
          ));
        trades
          ..clear()
          ..addAll(((map['trades'] as List?) ?? []).map(
            (e) => DemoTrade.fromJson(e as Map<String, dynamic>),
          ));
      } catch (_) {
        balance = startingBalance;
      }
    }
    _ready = true;
    notifyListeners();
  }

  String? openMarket({
    required String side,
    required double lots,
    required double bid,
    required double ask,
  }) {
    if (lots < 0.01) return 'Minimum volume is 0.01 lots';
    final price = side == 'BUY' ? ask : bid;
    if (price <= 0) return 'No quote';
    final margin = lots * 100;
    if (margin > balance) return 'Not enough demo margin';

    positions.insert(
      0,
      DemoPosition(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        symbol: symbol,
        side: side,
        lots: lots,
        openPrice: price,
        time: DateTime.now(),
      ),
    );
    _persist();
    notifyListeners();
    return null;
  }

  String? closePosition(String id, double bid, double ask) {
    final idx = positions.indexWhere((p) => p.id == id);
    if (idx < 0) return 'Position not found';
    final p = positions.removeAt(idx);
    final pnl = p.pnl(bid, ask);
    final closePrice = p.side == 'BUY' ? bid : ask;
    balance += pnl;
    trades.insert(
      0,
      DemoTrade(
        id: p.id,
        symbol: p.symbol,
        side: p.side,
        lots: p.lots,
        openPrice: p.openPrice,
        closePrice: closePrice,
        pnl: pnl,
        time: p.time,
        closeTime: DateTime.now(),
      ),
    );
    if (trades.length > 120) trades.removeRange(120, trades.length);
    _persist();
    notifyListeners();
    return null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'balance': balance,
        'positions': positions.map((p) => p.toJson()).toList(),
        'trades': trades.map((t) => t.toJson()).toList(),
      }),
    );
  }
}
