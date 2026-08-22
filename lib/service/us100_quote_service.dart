import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Live bid/ask for US100 (Nasdaq 100 CFD), used by the MT5-style trade bar.
class Us100QuoteService extends ChangeNotifier {
  Us100QuoteService._();
  static final Us100QuoteService instance = Us100QuoteService._();

  static const double typicalSpread = 0.90;

  double bid = 29295.54;
  double ask = 29296.44;
  bool live = false;
  Timer? _timer;
  int _listeners = 0;

  void attach() {
    _listeners++;
    if (_listeners == 1) {
      _refresh();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    }
  }

  void detach() {
    _listeners = max(0, _listeners - 1);
    if (_listeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _refresh() async {
    final quote = await _fromTradingView() ?? await _fromYahoo();
    if (quote != null) {
      bid = quote.$1;
      ask = quote.$2;
      live = true;
      notifyListeners();
      return;
    }
    // Keep the bar moving if the network quote is blocked (common on web CORS).
    final mid = (bid + ask) / 2;
    final tick = (Random().nextDouble() - 0.5) * 1.2;
    bid = mid + tick - typicalSpread / 2;
    ask = bid + typicalSpread;
    live = false;
    notifyListeners();
  }

  Future<(double, double)?> _fromTradingView() async {
    try {
      final res = await http
          .post(
            Uri.parse('https://scanner.tradingview.com/cfd/scan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'symbols': {
                'tickers': ['CAPITALCOM:US100']
              },
              'columns': ['bid', 'ask', 'close'],
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List?;
      if (data == null || data.isEmpty) return null;
      final cols = (data.first as Map)['d'] as List;
      final close = (cols.length > 2 ? cols[2] : cols[0]) as num;
      double b = cols[0] is num ? (cols[0] as num).toDouble() : close.toDouble();
      double a = cols[1] is num ? (cols[1] as num).toDouble() : close.toDouble();
      if (b <= 0 || a <= 0) {
        b = close.toDouble() - typicalSpread / 2;
        a = close.toDouble() + typicalSpread / 2;
      }
      if (a < b) a = b + typicalSpread;
      return (b, a);
    } catch (_) {
      return null;
    }
  }

  Future<(double, double)?> _fromYahoo() async {
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/NQ=F?range=1d&interval=1m',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0',
      }).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final meta = json['chart']?['result']?[0]?['meta'] as Map<String, dynamic>?;
      final price = (meta?['regularMarketPrice'] as num?)?.toDouble();
      if (price == null || price <= 0) return null;
      return (price - typicalSpread / 2, price + typicalSpread / 2);
    } catch (_) {
      return null;
    }
  }
}
