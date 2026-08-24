import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Maps a price onto the live TradingView pane using axis labels from JS.
class ChartScaleService extends ChangeNotifier {
  ChartScaleService._();
  static final ChartScaleService instance = ChartScaleService._();

  double _m = 0;
  double _c = 0;
  double last = 0;
  double? lastY;
  double paneHeight = 0;
  DateTime? updatedAt;
  DateTime? _fitAt;

  bool get fitted =>
      _m != 0 &&
      _fitAt != null &&
      DateTime.now().difference(_fitAt!) < const Duration(seconds: 8);

  bool get ready =>
      fitted ||
      (lastY != null &&
          last > 0 &&
          updatedAt != null &&
          DateTime.now().difference(updatedAt!) < const Duration(seconds: 8));

  void ingestJson(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return;
      final lastPx = (map['last'] as num?)?.toDouble() ?? 0;
      paneHeight = (map['h'] as num?)?.toDouble() ?? paneHeight;
      final list = map['samples'];
      if (list is! List || list.isEmpty) return;
      final pts = <({double p, double y})>[];
      for (final e in list) {
        if (e is! Map) continue;
        final p = (e['p'] as num?)?.toDouble() ?? 0;
        final y = (e['y'] as num?)?.toDouble() ?? 0;
        if (p <= 0) continue;
        if (lastPx > 0 && (p - lastPx).abs() / lastPx > 0.08) continue;
        pts.add((p: p, y: y));
      }
      if (pts.isEmpty) return;
      if (lastPx > 0) last = lastPx;
      pts.sort((a, b) => (a.p - last).abs().compareTo((b.p - last).abs()));
      lastY = pts.first.y;
      updatedAt = DateTime.now();

      if (pts.length >= 2) {
        final unique = <({double p, double y})>[];
        final sorted = [...pts]..sort((a, b) => a.p.compareTo(b.p));
        for (final s in sorted) {
          if (unique.isEmpty || (s.p - unique.last.p).abs() > 0.05) {
            unique.add(s);
          }
        }
        if (unique.length >= 2) {
          var sumP = 0.0, sumY = 0.0, sumPP = 0.0, sumPY = 0.0;
          for (final s in unique) {
            sumP += s.p;
            sumY += s.y;
            sumPP += s.p * s.p;
            sumPY += s.p * s.y;
          }
          final n = unique.length.toDouble();
          final den = n * sumPP - sumP * sumP;
          if (den.abs() > 1e-9) {
            final m = (n * sumPY - sumP * sumY) / den;
            if (m < 0) {
              _m = m;
              _c = (sumY - m * sumP) / n;
              _fitAt = DateTime.now();
            }
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  double? yOf(double price) {
    if (fitted) return _m * price + _c;
    if (lastY == null || last <= 0) return null;
    final span = max(80.0, last * 0.0045);
    final h = paneHeight > 80 ? paneHeight : 400.0;
    final ppm = h / span;
    return lastY! - (price - last) * ppm;
  }

  double? priceOf(double y) {
    if (fitted && _m.abs() > 1e-12) return (y - _c) / _m;
    if (lastY == null || last <= 0) return null;
    final span = max(80.0, last * 0.0045);
    final h = paneHeight > 80 ? paneHeight : 400.0;
    final ppm = h / span;
    return last + (lastY! - y) / ppm;
  }
}
