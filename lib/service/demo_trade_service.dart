import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'user_account_store.dart';

class DemoPosition {
  final String id;
  final String symbol;
  final String side; // BUY or SELL
  final double lots;
  final double openPrice;
  final DateTime time;
  final double? sl;
  final double? tp;

  const DemoPosition({
    required this.id,
    required this.symbol,
    required this.side,
    required this.lots,
    required this.openPrice,
    required this.time,
    this.sl,
    this.tp,
  });

  DemoPosition copyWith({double? sl, double? tp, bool clearSl = false, bool clearTp = false}) {
    return DemoPosition(
      id: id,
      symbol: symbol,
      side: side,
      lots: lots,
      openPrice: openPrice,
      time: time,
      sl: clearSl ? null : (sl ?? this.sl),
      tp: clearTp ? null : (tp ?? this.tp),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side,
        'lots': lots,
        'openPrice': openPrice,
        'time': time.toIso8601String(),
        'sl': sl,
        'tp': tp,
      };

  factory DemoPosition.fromJson(Map<String, dynamic> json) => DemoPosition(
        id: json['id']?.toString() ?? '',
        symbol: json['symbol'] as String? ?? 'US100',
        side: json['side'] as String? ?? 'BUY',
        lots: (json['lots'] as num?)?.toDouble() ?? 0,
        openPrice: (json['openPrice'] as num?)?.toDouble() ?? 0,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        sl: (json['sl'] as num?)?.toDouble(),
        tp: (json['tp'] as num?)?.toDouble(),
      );

  double pnl(double bid, double ask) {
    final exit = side == 'BUY' ? bid : ask;
    final delta = side == 'BUY' ? exit - openPrice : openPrice - exit;
    return delta * lots * pointValue;
  }

  bool hitTakeProfit(double bid, double ask) {
    if (tp == null) return false;
    return side == 'BUY' ? bid >= tp! : ask <= tp!;
  }

  bool hitStopLoss(double bid, double ask) {
    if (sl == null) return false;
    return side == 'BUY' ? bid <= sl! : ask >= sl!;
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
  final double? sl;
  final double? tp;
  final String closeReason;
  final String? review;

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
    this.sl,
    this.tp,
    this.closeReason = 'manual',
    this.review,
  });

  DemoTrade copyWith({String? review}) {
    return DemoTrade(
      id: id,
      symbol: symbol,
      side: side,
      lots: lots,
      openPrice: openPrice,
      closePrice: closePrice,
      pnl: pnl,
      time: time,
      closeTime: closeTime,
      sl: sl,
      tp: tp,
      closeReason: closeReason,
      review: review ?? this.review,
    );
  }

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
        'sl': sl,
        'tp': tp,
        'closeReason': closeReason,
        'review': review,
      };

  factory DemoTrade.fromJson(Map<String, dynamic> json) => DemoTrade(
        id: json['id']?.toString() ?? '',
        symbol: json['symbol'] as String? ?? 'US100',
        side: json['side'] as String? ?? 'BUY',
        lots: (json['lots'] as num?)?.toDouble() ?? 0,
        openPrice: (json['openPrice'] as num?)?.toDouble() ?? 0,
        closePrice: (json['closePrice'] as num?)?.toDouble() ?? 0,
        pnl: (json['pnl'] as num?)?.toDouble() ?? 0,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        closeTime: DateTime.tryParse(
              (json['closeTime'] as String?) ?? json['time'] as String? ?? '',
            ) ??
            DateTime.now(),
        sl: (json['sl'] as num?)?.toDouble(),
        tp: (json['tp'] as num?)?.toDouble(),
        closeReason: json['closeReason'] as String? ?? 'manual',
        review: json['review'] as String?,
      );
}

/// Paper US100 account. Orders are stored per signed-in user.
class DemoTradeService extends ChangeNotifier {
  DemoTradeService._();
  static final DemoTradeService instance = DemoTradeService._();

  static const double startingBalance = 10000;
  static const String symbol = 'US100';

  bool _ready = false;
  String? _boundUid;
  String? _appliedUpdatedAt;
  bool _listeningStore = false;
  double balance = startingBalance;
  final List<DemoPosition> positions = [];
  final List<DemoTrade> trades = [];

  bool get isReady => _ready;

  Future<void> init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      resetMemory();
      return;
    }
    final store = UserAccountStore.instance;
    await store.bindToCurrentUser();
    _boundUid = uid;
    if (!_listeningStore) {
      _listeningStore = true;
      store.addListener(_onStore);
    }
    _applyFromStore(force: true);
    _ready = true;
    notifyListeners();
  }

  void _onStore() {
    if (_boundUid == null || _boundUid != UserAccountStore.instance.uid) return;
    _applyFromStore();
  }

  void _applyFromStore({bool force = false}) {
    final store = UserAccountStore.instance;
    if (!force && store.updatedAtIso == _appliedUpdatedAt) return;
    try {
      balance = store.demoBalance;
      positions
        ..clear()
        ..addAll(store.demoPositions.map(DemoPosition.fromJson));
      trades
        ..clear()
        ..addAll(store.demoTrades.map(DemoTrade.fromJson));
      _appliedUpdatedAt = store.updatedAtIso;
    } catch (_) {
      if (!_ready) {
        balance = startingBalance;
        positions.clear();
        trades.clear();
      }
    }
    if (_ready) notifyListeners();
  }

  void resetMemory() {
    _ready = false;
    _boundUid = null;
    _appliedUpdatedAt = null;
    balance = startingBalance;
    positions.clear();
    trades.clear();
    notifyListeners();
  }

  Future<void> flushAndReset() async {
    if (_ready && _boundUid != null) {
      await _persist();
    }
    resetMemory();
  }

  String? adjustBalance(double delta, {required String label}) {
    if (delta == 0) return 'Enter an amount';
    final next = balance + delta;
    if (next < 0) return 'Not enough balance';
    balance = next;
    UserAccountStore.instance.addWalletActivity(
      WalletActivity(
        label: label,
        amount: delta.abs(),
        isPositive: delta > 0,
        time: DateTime.now(),
      ),
    );
    _persist();
    notifyListeners();
    return null;
  }

  /// Absolute price, or MT5-style distance in points when the value is small.
  static double? resolveLevel({
    required String side,
    required bool isStopLoss,
    required double fill,
    double? raw,
  }) {
    if (raw == null || raw <= 0) return null;
    final asPrice = raw >= 10000;
    if (asPrice) return raw;
    return isStopLoss
        ? (side == 'BUY' ? fill - raw : fill + raw)
        : (side == 'BUY' ? fill + raw : fill - raw);
  }

  String? openMarket({
    required String side,
    required double lots,
    required double bid,
    required double ask,
    double? sl,
    double? tp,
  }) {
    if (lots < 0.01) return 'Minimum volume is 0.01 lots';
    final price = side == 'BUY' ? ask : bid;
    if (price <= 0) return 'No live quote — wait for the price to load';
    final margin = lots * 100;
    if (margin > balance) return 'Not enough demo margin';
    final slPx = resolveLevel(side: side, isStopLoss: true, fill: price, raw: sl);
    final tpPx = resolveLevel(side: side, isStopLoss: false, fill: price, raw: tp);
    final slErr = _validateLevels(side: side, open: price, sl: slPx, tp: tpPx);
    if (slErr != null) return slErr;

    positions.insert(
      0,
      DemoPosition(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        symbol: symbol,
        side: side,
        lots: lots,
        openPrice: price,
        time: DateTime.now(),
        sl: slPx,
        tp: tpPx,
      ),
    );
    _persist();
    notifyListeners();
    applyStops(bid, ask);
    return null;
  }

  String? updateLevels(String id, {double? sl, double? tp, bool clearSl = false, bool clearTp = false}) {
    final idx = positions.indexWhere((p) => p.id == id);
    if (idx < 0) return 'Position not found';
    final p = positions[idx];
    final nextSl = clearSl
        ? null
        : resolveLevel(
              side: p.side,
              isStopLoss: true,
              fill: p.openPrice,
              raw: sl,
            ) ??
            (sl == null ? p.sl : sl);
    final nextTp = clearTp
        ? null
        : resolveLevel(
              side: p.side,
              isStopLoss: false,
              fill: p.openPrice,
              raw: tp,
            ) ??
            (tp == null ? p.tp : tp);
    final err = _validateLevels(side: p.side, open: p.openPrice, sl: nextSl, tp: nextTp);
    if (err != null) return err;
    positions[idx] = p.copyWith(sl: nextSl, tp: nextTp, clearSl: nextSl == null, clearTp: nextTp == null);
    _persist();
    notifyListeners();
    return null;
  }

  String? setAbsoluteLevels(String id, {double? sl, double? tp}) {
    final idx = positions.indexWhere((p) => p.id == id);
    if (idx < 0) return 'Position not found';
    final p = positions[idx];
    final nextSl = sl;
    final nextTp = tp;
    final err = _validateLevels(side: p.side, open: p.openPrice, sl: nextSl, tp: nextTp);
    if (err != null) return err;
    positions[idx] = p.copyWith(
      sl: nextSl,
      tp: nextTp,
      clearSl: nextSl == null,
      clearTp: nextTp == null,
    );
    _persist();
    notifyListeners();
    return null;
  }

  String? _validateLevels({
    required String side,
    required double open,
    double? sl,
    double? tp,
  }) {
    if (sl != null && sl <= 0) return 'SL must be greater than 0';
    if (tp != null && tp <= 0) return 'TP must be greater than 0';
    if (side == 'BUY') {
      if (sl != null && sl >= open) return 'Buy SL must be below open price';
      if (tp != null && tp <= open) return 'Buy TP must be above open price';
    } else {
      if (sl != null && sl <= open) return 'Sell SL must be above open price';
      if (tp != null && tp >= open) return 'Sell TP must be below open price';
    }
    return null;
  }

  String? closePosition(
    String id,
    double bid,
    double ask, {
    String reason = 'manual',
    double? atPrice,
  }) {
    final idx = positions.indexWhere((p) => p.id == id);
    if (idx < 0) return 'Position not found';
    final p = positions.removeAt(idx);
    final closePrice = atPrice ?? (p.side == 'BUY' ? bid : ask);
    final delta =
        p.side == 'BUY' ? closePrice - p.openPrice : p.openPrice - closePrice;
    final pnl = delta * p.lots * DemoPosition.pointValue;
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
        sl: p.sl,
        tp: p.tp,
        closeReason: reason,
      ),
    );
    if (trades.length > 400) trades.removeRange(400, trades.length);
    _persist();
    notifyListeners();
    return null;
  }

  void setTradeReview(String id, String review) {
    final idx = trades.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    if (trades[idx].review == review) return;
    trades[idx] = trades[idx].copyWith(review: review);
    _persist();
    notifyListeners();
  }

  void applyStops(double bid, double ask) {
    if (positions.isEmpty) return;
    final hits = <({String id, String reason, double at})>[];
    for (final p in List<DemoPosition>.from(positions)) {
      if (p.hitStopLoss(bid, ask) && p.sl != null) {
        hits.add((id: p.id, reason: 'sl', at: p.sl!));
      } else if (p.hitTakeProfit(bid, ask) && p.tp != null) {
        hits.add((id: p.id, reason: 'tp', at: p.tp!));
      }
    }
    for (final h in hits) {
      closePosition(h.id, bid, ask, reason: h.reason, atPrice: h.at);
    }
  }

  Future<void> _persist() async {
    await UserAccountStore.instance.saveAll(
      demoBalance: balance,
      positions: positions.map((p) => p.toJson()).toList(),
      trades: trades.map((t) => t.toJson()).toList(),
    );
    _appliedUpdatedAt = UserAccountStore.instance.updatedAtIso;
  }
}
