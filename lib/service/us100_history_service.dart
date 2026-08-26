import 'dart:convert';

import 'package:http/http.dart' as http;

import '../content/smc/smc_models.dart';
import 'us100_quote_service.dart';

/// Historical US100 (Nasdaq-100) bars for Quiz replay. Cached in memory.
class Us100HistoryService {
  Us100HistoryService._();
  static final Us100HistoryService instance = Us100HistoryService._();

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  List<SmcCandle>? _cache;
  DateTime? _cacheAt;

  Future<List<SmcCandle>> load15m({bool force = false}) async {
    if (!force &&
        _cache != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < const Duration(minutes: 8)) {
      return _cache!;
    }
    final bars = await _fromYahoo() ?? await _fromYahooFutures();
    if (bars != null && bars.length >= 40) {
      _cache = bars;
      _cacheAt = DateTime.now();
      return bars;
    }
    return _synthetic();
  }

  Future<List<SmcCandle>?> _fromYahoo() => _chart(
        'https://query1.finance.yahoo.com/v8/finance/chart/%5ENDX?interval=15m&range=5d',
      );

  Future<List<SmcCandle>?> _fromYahooFutures() => _chart(
        'https://query1.finance.yahoo.com/v8/finance/chart/NQ%3DF?interval=15m&range=5d',
      );

  Future<List<SmcCandle>?> _chart(String url) async {
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': _ua,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map) return null;
      final result = (json['chart'] as Map?)?['result'] as List?;
      if (result == null || result.isEmpty) return null;
      final first = result.first as Map;
      final ts = (first['timestamp'] as List?) ?? const [];
      final quote = ((first['indicators'] as Map?)?['quote'] as List?)?.first;
      if (quote is! Map) return null;
      final o = quote['open'] as List? ?? const [];
      final h = quote['high'] as List? ?? const [];
      final l = quote['low'] as List? ?? const [];
      final c = quote['close'] as List? ?? const [];
      final n = ts.length;
      final out = <SmcCandle>[];
      for (var i = 0; i < n; i++) {
        final ov = _n(i < o.length ? o[i] : null);
        final hv = _n(i < h.length ? h[i] : null);
        final lv = _n(i < l.length ? l[i] : null);
        final cv = _n(i < c.length ? c[i] : null);
        if (ov <= 0 || hv <= 0 || lv <= 0 || cv <= 0) continue;
        DateTime? t;
        final raw = i < ts.length ? ts[i] : null;
        if (raw is num) {
          t = DateTime.fromMillisecondsSinceEpoch(raw.toInt() * 1000, isUtc: true);
        }
        out.add(SmcCandle(open: ov, high: hv, low: lv, close: cv, time: t));
      }
      return out.length >= 40 ? out : null;
    } catch (_) {
      return null;
    }
  }

  double _n(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  List<SmcCandle> _synthetic() {
    final last = Us100QuoteService.instance.last;
    var p = last > 1000 ? last : 29200.0;
    final out = <SmcCandle>[];
    var t = DateTime.now().toUtc().subtract(const Duration(minutes: 15 * 120));
    var seed = 17;
    int rnd() {
      seed = (1103515245 * seed + 12345) & 0x7fffffff;
      return seed;
    }

    for (var i = 0; i < 120; i++) {
      final drift = ((rnd() % 1000) / 1000 - 0.48) * 32;
      final o = p;
      final c = p + drift;
      final w = (rnd() % 140) / 10;
      final high = (o > c ? o : c) + w;
      final low = (o < c ? o : c) - w * 0.8;
      out.add(SmcCandle(open: o, high: high, low: low, close: c, time: t));
      p = c;
      t = t.add(const Duration(minutes: 15));
    }
    return out;
  }
}
