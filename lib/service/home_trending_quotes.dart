import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'us100_quote_service.dart';

class HomeMarketQuote {
  const HomeMarketQuote({
    required this.symbol,
    this.price = 0,
    this.changePct = 0,
    this.volume = '—',
    this.spark = const [],
  });

  final String symbol;
  final double price;
  final double changePct;
  final String volume;
  final List<double> spark;

  HomeMarketQuote copyWith({
    double? price,
    double? changePct,
    String? volume,
    List<double>? spark,
  }) {
    return HomeMarketQuote(
      symbol: symbol,
      price: price ?? this.price,
      changePct: changePct ?? this.changePct,
      volume: volume ?? this.volume,
      spark: spark ?? this.spark,
    );
  }
}

/// Live US100 / BTC / ETH quotes for the Home trending list only.
class HomeTrendingQuotes extends ChangeNotifier {
  HomeTrendingQuotes._();
  static final HomeTrendingQuotes instance = HomeTrendingQuotes._();

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  List<HomeMarketQuote> markets = const [
    HomeMarketQuote(symbol: 'US100', volume: 'NDX'),
    HomeMarketQuote(symbol: 'BTC/USDT'),
    HomeMarketQuote(symbol: 'ETH/USDT'),
  ];

  Timer? _timer;
  int _listeners = 0;
  Future<void>? _inFlight;
  DateTime? _lastSparkAt;

  void attach() {
    _listeners++;
    if (_listeners == 1) {
      _seedUs100();
      refreshNow();
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => refreshNow());
    }
  }

  void detach() {
    _listeners = max(0, _listeners - 1);
    if (_listeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> refreshNow() {
    _inFlight ??= _refreshAll().whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  void _seedUs100() {
    final live = Us100QuoteService.instance;
    if (!live.hasQuote) return;
    _set('US100', quote('US100').copyWith(price: live.last));
    notifyListeners();
  }

  HomeMarketQuote quote(String symbol) {
    return markets.firstWhere(
      (m) => m.symbol == symbol,
      orElse: () => HomeMarketQuote(symbol: symbol),
    );
  }

  Future<void> _refreshAll() async {
    final needSpark = _lastSparkAt == null ||
        DateTime.now().difference(_lastSparkAt!) > const Duration(seconds: 30);
    await Future.wait([
      _refreshUs100(needSpark: needSpark),
      _refreshCrypto(
        display: 'BTC/USDT',
        binance: 'BTCUSDT',
        tv: 'BINANCE:BTCUSDT',
        geckoId: 'bitcoin',
        needSpark: needSpark,
      ),
      _refreshCrypto(
        display: 'ETH/USDT',
        binance: 'ETHUSDT',
        tv: 'BINANCE:ETHUSDT',
        geckoId: 'ethereum',
        needSpark: needSpark,
      ),
    ]);
    if (needSpark) _lastSparkAt = DateTime.now();
    notifyListeners();
  }

  void _set(String symbol, HomeMarketQuote next) {
    markets = [
      for (final m in markets)
        if (m.symbol == symbol) next else m,
    ];
  }

  Future<void> _refreshUs100({required bool needSpark}) async {
    final prev = quote('US100');
    var price = prev.price;
    var change = prev.changePct;
    var spark = prev.spark;
    const volume = 'NDX';

    try {
      final y = await _yahooNdx(needSpark: needSpark);
      if (y != null) {
        price = y.$1;
        change = y.$2;
        if (y.$3 != null && y.$3!.length >= 2) spark = y.$3!;
      }
    } catch (_) {}

    if (price <= 0) {
      final live = Us100QuoteService.instance;
      if (live.hasQuote) price = live.last;
    }

    if (price <= 0) {
      try {
        final tv = await _tradingView('NASDAQ:NDX');
        if (tv != null) {
          price = tv.$1;
          if (tv.$2 != null) change = tv.$2!;
        }
      } catch (_) {}
    }

    if (price > 0) {
      _set(
        'US100',
        prev.copyWith(price: price, changePct: change, volume: volume, spark: spark),
      );
    }
  }

  Future<void> _refreshCrypto({
    required String display,
    required String binance,
    required String tv,
    required String geckoId,
    required bool needSpark,
  }) async {
    final prev = quote(display);
    var price = prev.price;
    var change = prev.changePct;
    var volume = prev.volume;
    var spark = prev.spark;

    try {
      final t = await _binanceTicker(binance);
      if (t != null) {
        price = t.$1;
        change = t.$2;
        volume = _fmtVol(t.$3);
      }
    } catch (_) {}

    if (price <= 0) {
      try {
        final s = await _tradingView(tv);
        if (s != null) {
          price = s.$1;
          if (s.$2 != null) change = s.$2!;
        }
      } catch (_) {}
    }

    if (price <= 0) {
      try {
        final g = await _coinGecko(geckoId);
        if (g != null) {
          price = g.$1;
          change = g.$2;
        }
      } catch (_) {}
    }

    if (needSpark) {
      try {
        final k = await _binanceSpark(binance);
        if (k != null && k.length >= 2) spark = k;
      } catch (_) {}
    }

    if (price > 0) {
      _set(
        display,
        prev.copyWith(
          price: price,
          changePct: change,
          volume: volume,
          spark: spark,
        ),
      );
    }
  }

  Map<String, String> get _jsonHeaders => {
        'User-Agent': _ua,
        'Accept': 'application/json',
      };

  Map<String, String> get _tvHeaders => {
        'User-Agent': _ua,
        'Accept': 'application/json,text/plain,*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Origin': 'https://www.tradingview.com',
        'Referer': 'https://www.tradingview.com/',
      };

  Future<(double, double, double)?> _binanceTicker(String symbol) async {
    final hosts = [
      'https://api.binance.com/api/v3/ticker/24hr',
      'https://data-api.binance.vision/api/v3/ticker/24hr',
    ];
    for (final host in hosts) {
      try {
        final res = await http
            .get(Uri.parse('$host?symbol=$symbol'), headers: _jsonHeaders)
            .timeout(const Duration(seconds: 5));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body);
        if (json is! Map) continue;
        final price = _num(json['lastPrice']);
        if (price <= 0) continue;
        return (
          price,
          _num(json['priceChangePercent']),
          _num(json['quoteVolume']),
        );
      } catch (_) {}
    }
    return null;
  }

  Future<List<double>?> _binanceSpark(String symbol) async {
    final hosts = [
      'https://api.binance.com/api/v3/klines',
      'https://data-api.binance.vision/api/v3/klines',
    ];
    for (final host in hosts) {
      try {
        final res = await http
            .get(
              Uri.parse('$host?symbol=$symbol&interval=15m&limit=12'),
              headers: _jsonHeaders,
            )
            .timeout(const Duration(seconds: 5));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body);
        if (json is! List) continue;
        final closes = <double>[];
        for (final row in json) {
          if (row is List && row.length > 4) {
            final c = _num(row[4]);
            if (c > 0) closes.add(c);
          }
        }
        if (closes.length >= 2) return closes;
      } catch (_) {}
    }
    return null;
  }

  Future<(double, double?)?> _tradingView(String ticker) async {
    final uri = Uri.https('scanner.tradingview.com', '/symbol', {
      'symbol': ticker,
      'fields': 'lp,close,chp,change,volume',
    });
    final res = await http
        .get(uri, headers: _tvHeaders)
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body);
    if (json is! Map) return null;
    final last = _num(json['lp']) > 0 ? _num(json['lp']) : _num(json['close']);
    if (last <= 0) return null;
    final chp = _num(json['chp']);
    final change = chp != 0 ? chp : _num(json['change']);
    return (last, change == 0 ? null : change);
  }

  Future<(double, double)?> _coinGecko(String id) async {
    final uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
      'ids': id,
      'vs_currencies': 'usd',
      'include_24hr_change': 'true',
      'include_24hr_vol': 'true',
    });
    final res = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body);
    if (json is! Map) return null;
    final row = json[id];
    if (row is! Map) return null;
    final price = _num(row['usd']);
    if (price <= 0) return null;
    return (price, _num(row['usd_24h_change']));
  }

  Future<(double, double, List<double>?)?> _yahooNdx({
    required bool needSpark,
  }) async {
    final uri = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/%5ENDX?interval=5m&range=1d',
    );
    final res = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final result = (json['chart'] as Map?)?['result'] as List?;
    if (result == null || result.isEmpty) return null;
    final first = result.first as Map;
    final meta = first['meta'] as Map? ?? {};
    final last = _num(meta['regularMarketPrice']) > 0
        ? _num(meta['regularMarketPrice'])
        : _num(meta['previousClose']);
    if (last <= 0) return null;
    final prevClose = _num(meta['previousClose']) > 0
        ? _num(meta['previousClose'])
        : _num(meta['chartPreviousClose']);
    var change = _num(meta['regularMarketChangePercent']);
    if (change == 0 && prevClose > 0) {
      change = (last - prevClose) / prevClose * 100;
    }

    List<double>? spark;
    if (needSpark) {
      try {
        final quote = ((first['indicators'] as Map?)?['quote'] as List?)?.first;
        if (quote is Map) {
          final closes = quote['close'] as List? ?? const [];
          final pts = <double>[];
          for (final c in closes) {
            final n = _num(c);
            if (n > 0) pts.add(n);
          }
          if (pts.length >= 2) {
            spark = pts.length <= 12 ? pts : pts.sublist(pts.length - 12);
          }
        }
      } catch (_) {}
    }
    return (last, change, spark);
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _fmtVol(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    if (v <= 0) return '—';
    return v.toStringAsFixed(0);
  }
}
