import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'demo_trade_service.dart';

/// Live bid/ask for the same US100 cash CFD shown on the TradingView chart.
class Us100QuoteService extends ChangeNotifier {
  Us100QuoteService._();
  static final Us100QuoteService instance = Us100QuoteService._();

  static const double typicalSpread = 0.90;
  static const String ticker = 'CAPITALCOM:US100';
  static const _browserUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  double last = 0;
  double bid = 0;
  double ask = 0;
  DateTime? updatedAt;
  DateTime? _chartTickAt;
  Future<void>? _inFlight;
  Timer? _timer;
  int _listeners = 0;

  bool get hasQuote => last > 0 && bid > 0 && ask > 0;

  bool get live =>
      hasQuote &&
      updatedAt != null &&
      DateTime.now().difference(updatedAt!) < const Duration(seconds: 15);

  void attach() {
    _listeners++;
    if (_listeners == 1) {
      refreshNow();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => refreshNow());
    }
  }

  void detach() {
    _listeners = max(0, _listeners - 1);
    if (_listeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Chart last price (same number shown on TradingView). Spread is synthetic.
  void ingestChartLast(double lastPx) {
    if (lastPx <= 0) return;
    if (last > 0) {
      if ((lastPx - last).abs() / last > 0.12) return;
    } else if (lastPx < 50) {
      return;
    }
    _chartTickAt = DateTime.now();
    _apply(lastPx, lastPx - typicalSpread / 2, lastPx + typicalSpread / 2);
  }

  Future<void> refreshNow() {
    _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<void> _doRefresh() async {
    final chartFresh = _chartTickAt != null &&
        DateTime.now().difference(_chartTickAt!) < const Duration(seconds: 2);
    if (chartFresh) return;

    final quote = await _fromAnyHttp();
    if (quote == null) {
      if (hasQuote &&
          updatedAt != null &&
          DateTime.now().difference(updatedAt!) > const Duration(seconds: 12)) {
        notifyListeners();
      }
      return;
    }
    _apply(quote.$1, quote.$2, quote.$3);
  }

  void _apply(double lastPx, double b, double a) {
    last = lastPx;
    bid = b;
    ask = a;
    updatedAt = DateTime.now();
    notifyListeners();
    if (hasQuote) {
      DemoTradeService.instance.applyStops(bid, ask);
    }
  }

  Future<(double, double, double)?> _fromAnyHttp() async {
    final sources = <Future<(double, double, double)?> Function()>[
      _fromTradingViewSymbol,
      _fromTradingViewScan,
      _fromYahooNdx,
    ];
    for (final src in sources) {
      try {
        final q = await src();
        if (q != null && q.$1 > 0) return _withSpread(q.$1, q.$2, q.$3);
      } catch (_) {}
    }
    return null;
  }

  (double, double, double) _withSpread(double lastPx, double b, double a) {
    final spreadOk = b > 0 && a > 0 && a >= b && (a - b) < 8;
    final nearLast =
        spreadOk && (b - lastPx).abs() < 6 && (a - lastPx).abs() < 6;
    if (!nearLast) {
      b = lastPx - typicalSpread / 2;
      a = lastPx + typicalSpread / 2;
    }
    return (lastPx, b, a);
  }

  Map<String, String> get _headers => {
        'User-Agent': _browserUa,
        'Accept': 'application/json,text/plain,*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Origin': 'https://www.tradingview.com',
        'Referer': 'https://www.tradingview.com/',
        'Content-Type': 'application/json',
      };

  Future<(double, double, double)?> _fromTradingViewSymbol() async {
    final uri = Uri.https('scanner.tradingview.com', '/symbol', {
      'symbol': ticker,
      'fields': 'lp,bid,ask,close',
    });
    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body);
    if (json is! Map) return null;
    double n(String k) {
      final v = json[k];
      if (v is num) return v.toDouble();
      return 0;
    }

    final lastPx = n('lp') > 0 ? n('lp') : n('close');
    if (lastPx <= 0) return null;
    return (lastPx, n('bid'), n('ask'));
  }

  Future<(double, double, double)?> _fromTradingViewScan() async {
    Future<(double, double, double)?> scan(String path) async {
      final res = await http
          .post(
            Uri.parse('https://scanner.tradingview.com/$path'),
            headers: _headers,
            body: jsonEncode({
              'symbols': {
                'tickers': [ticker]
              },
              'columns': ['close', 'bid', 'ask', 'lp'],
            }),
          )
          .timeout(const Duration(seconds: 5));
      return _parseScan(res);
    }

    return await scan('cfd/scan') ?? await scan('america/scan');
  }

  Future<(double, double, double)?> _fromYahooNdx() async {
    final uri = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/%5ENDX?interval=1m&range=1d',
    );
    final res = await http.get(uri, headers: {
      'User-Agent': _browserUa,
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final result = (json['chart'] as Map?)?['result'] as List?;
    if (result == null || result.isEmpty) return null;
    final meta = (result.first as Map)['meta'] as Map? ?? {};
    double n(String k) {
      final v = meta[k];
      if (v is num) return v.toDouble();
      return 0;
    }

    final lastPx = n('regularMarketPrice') > 0
        ? n('regularMarketPrice')
        : n('previousClose');
    if (lastPx <= 0) return null;
    return (lastPx, n('bid'), n('ask'));
  }

  (double, double, double)? _parseScan(http.Response res) {
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as List?;
    if (data == null || data.isEmpty) return null;
    final cols = (data.first as Map)['d'] as List;
    double numAt(int i) {
      if (i >= cols.length || cols[i] is! num) return 0;
      return (cols[i] as num).toDouble();
    }

    final close = numAt(0);
    final b = numAt(1);
    final a = numAt(2);
    final lp = numAt(3);
    final lastPx = close > 0 ? close : lp;
    if (lastPx <= 0) return null;
    return (lastPx, b, a);
  }
}
