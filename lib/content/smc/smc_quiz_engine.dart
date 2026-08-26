import 'dart:math';

import 'package:flutter/material.dart';

import '../../service/us100_quote_service.dart';
import 'smc_catalog.dart';
import 'smc_models.dart';

const _g = Color(0xFF26A69A);
const _r = Color(0xFFEF5350);
const _b = Color(0xFF42A5F5);
const _o = Color(0xFFFFB74D);
const _p = Color(0xFFAB47BC);
const _c = Color(0xFF26C6DA);
const _gold = Color(0xFFFFD54F);

enum QuizIntent { buy, sell, range }

extension QuizIntentX on QuizIntent {
  String get label => switch (this) {
        QuizIntent.buy => 'Buy',
        QuizIntent.sell => 'Sell',
        QuizIntent.range => 'Range',
      };

  String get short => switch (this) {
        QuizIntent.buy => 'BUY',
        QuizIntent.sell => 'SELL',
        QuizIntent.range => 'RANG',
      };

  Color get color => switch (this) {
        QuizIntent.buy => _g,
        QuizIntent.sell => _r,
        QuizIntent.range => _gold,
      };

  String get quizKey => name;
}

class QuizClip {
  QuizClip({
    required this.topicId,
    required this.intent,
    required this.candles,
    required this.freezeIndex,
    required this.prompt,
    required this.marks,
    required this.theory,
  });

  final String topicId;
  final QuizIntent intent;
  final List<SmcCandle> candles;
  final int freezeIndex;
  final String prompt;
  final List<SmcMark> marks;
  final String theory;

  SmcCandle get entryBar => candles[freezeIndex];
  SmcCandle get exitBar => candles.last;

  double get points => exitBar.close - entryBar.close;

  ({double high, double low}) get futureRange {
    var hi = candles[freezeIndex].high;
    var lo = candles[freezeIndex].low;
    for (var i = freezeIndex; i < candles.length; i++) {
      if (candles[i].high > hi) hi = candles[i].high;
      if (candles[i].low < lo) lo = candles[i].low;
    }
    return (high: hi, low: lo);
  }
}

List<QuizIntent> shuffledQuizRound() {
  final round = List<QuizIntent>.from(QuizIntent.values)..shuffle(Random());
  return round;
}

int newQuizSalt() => Random().nextInt(1 << 30);

QuizClip buildQuizClip({
  required String topicId,
  required QuizIntent intent,
  int salt = 0,
}) {
  final live = Us100QuoteService.instance.last;
  final base = live > 1000 ? live : 29240.0;
  final seed = Object.hash(topicId, salt, intent.index, 0x9e3779b9);
  final start = DateTime.now().toUtc().subtract(Duration(minutes: 15 * (32 + salt.abs() % 48)));
  final px = base + ((seed % 361) - 180) + (salt.abs() % 79);
  final vol = 0.7 + (seed.abs() % 90) / 100.0;
  final pen = _Pen(px, seed ^ salt, start, vol: vol);

  _paintSetup(pen, topicId);
  final freeze = pen.out.length - 1;
  _paintFuture(pen, topicId, intent);

  final candles = pen.out;
  final topic = smcTopicById(topicId);
  final marks = _marksFor(topicId, candles, freeze);
  final startPx = candles[freeze].close;
  final endPx = candles.last.close;

  marks.add(SmcMark.tag(i0: freeze, price: startPx, label: 'NOW', color: _c));
  if (intent == QuizIntent.range) {
    final fr = () {
      var hi = candles[freeze].high;
      var lo = candles[freeze].low;
      for (var i = freeze; i < candles.length; i++) {
        if (candles[i].high > hi) hi = candles[i].high;
        if (candles[i].low < lo) lo = candles[i].low;
      }
      return (hi: hi, lo: lo);
    }();
    marks.add(SmcMark.box(
      i0: freeze,
      i1: candles.length - 1,
      low: fr.lo,
      high: fr.hi,
      label: 'Range / RANG',
      color: _gold,
    ));
  } else {
    marks.add(SmcMark.line(
      price: startPx,
      label: 'entry',
      color: _c,
      i0: freeze,
      i1: candles.length - 1,
    ));
    marks.add(SmcMark.tag(
      i0: candles.length - 1,
      price: endPx,
      label: intent == QuizIntent.buy ? 'TARGET ↑' : 'TARGET ↓',
      color: intent == QuizIntent.buy ? _g : _r,
    ));
  }

  return QuizClip(
    topicId: topicId,
    intent: intent,
    candles: candles,
    freezeIndex: freeze,
    prompt: _prompt(topic?.code ?? 'SMC'),
    marks: marks,
    theory: _theory(topic: topic, intent: intent, start: startPx, end: endPx),
  );
}

class _Pen {
  _Pen(this.px, int seed, DateTime t, {this.vol = 1})
      : _seed = seed,
        _t = t;

  double px;
  final double vol;
  int _seed;
  DateTime _t;
  final out = <SmcCandle>[];

  double r() {
    _seed = (1103515245 * _seed + 12345) & 0x7fffffff;
    return (_seed % 10000) / 10000.0;
  }

  void bar(num drift, {double wick = 7}) {
    final o = px;
    final c = o + drift.toDouble();
    final w = wick * vol;
    final hi = (o > c ? o : c) + 2 + r() * w;
    final lo = (o < c ? o : c) - 2 - r() * w * 0.85;
    out.add(SmcCandle(open: o, high: hi, low: lo, close: c, time: _t));
    px = c;
    _t = _t.add(const Duration(minutes: 15));
  }

  void nBars(int n, num total, {double wick = 7}) {
    final t = total.toDouble();
    var left = t;
    for (var i = 0; i < n; i++) {
      final piece = i == n - 1 ? left : t / n + (r() - 0.5) * (t.abs() * 0.22);
      left -= piece;
      bar(piece, wick: wick);
    }
  }

  void chop(int n, num width) {
    final mid = px;
    final w = width.toDouble();
    for (var i = 0; i < n; i++) {
      final target = mid + (r() - 0.5) * w;
      bar(target - px, wick: w * 0.18);
    }
  }

  void bullFvg({num gap = 18}) {
    bar(3, wick: 4);
    final c1High = out.last.high;
    nBars(1, gap.toDouble() + 16, wick: 5);
    final need = c1High + 2 - px;
    bar(need < 4 ? 6 : need, wick: 4);
  }

  void bearFvg({num gap = 18}) {
    bar(-3, wick: 4);
    final c1Low = out.last.low;
    nBars(1, -(gap.toDouble() + 16), wick: 5);
    final need = c1Low - 2 - px;
    bar(need > -4 ? -6 : need, wick: 4);
  }
}

void _paintSetup(_Pen p, String id) {
  final flip = p.r() >= 0.5;
  double s(num x) => flip ? -x.toDouble() : x.toDouble();
  final v = p.r();
  final chopN = 4 + (p.r() * 8).floor();
  final chopW = 7 + p.r() * 10;

  switch (id) {
    case 'fvg':
      p.chop(chopN, chopW);
      p.nBars(5 + (p.r() * 4).floor(), s(-16 - p.r() * 14));
      if (flip) {
        p.bearFvg(gap: 12 + p.r() * 12);
      } else {
        p.bullFvg(gap: 12 + p.r() * 12);
      }
      p.nBars(2, s(4 + p.r() * 6));
      break;
    case 'ifvg':
      p.nBars(6 + (p.r() * 5).floor(), s(22 + p.r() * 16));
      if (flip) {
        p.bearFvg(gap: 12 + p.r() * 10);
      } else {
        p.bullFvg(gap: 12 + p.r() * 10);
      }
      if (v < 0.34) {
        p.chop(6, 9 + p.r() * 6);
      } else if (v < 0.67) {
        p.nBars(5, s(-28 - p.r() * 18));
      } else {
        p.chop(8, 12 + p.r() * 6);
      }
      break;
    case 'bpr':
      p.nBars(4 + (p.r() * 4).floor(), s(16 + p.r() * 12));
      p.bearFvg(gap: 8 + p.r() * 10);
      p.nBars(3, s(-8 - p.r() * 8));
      p.bullFvg(gap: 8 + p.r() * 10);
      p.chop(3 + (p.r() * 4).floor(), 8 + p.r() * 8);
      break;
    case 'volume-imbalance':
      p.nBars(8 + (p.r() * 5).floor(), s(-10 - p.r() * 12));
      p.bar(s(12 + p.r() * 8), wick: 2);
      p.bar(s(9 + p.r() * 6), wick: 2);
      p.chop(5 + (p.r() * 4).floor(), 8 + p.r() * 6);
      break;
    case 'liquidity':
      p.nBars(6 + (p.r() * 5).floor(), s(-20 - p.r() * 10));
      p.chop(5 + (p.r() * 4).floor(), 6 + p.r() * 6);
      final eq = p.px + s(-4);
      p.bar(eq - p.px, wick: 3);
      p.nBars(3 + (p.r() * 3).floor(), s(8 + p.r() * 6));
      p.bar(eq + s(-12 - p.r() * 8) - p.px, wick: 5);
      break;
    case 'turtle-soup':
      p.nBars(5 + (p.r() * 5).floor(), s(14 + p.r() * 12));
      p.chop(6 + (p.r() * 5).floor(), 6 + p.r() * 5);
      p.bar(s(-14 - p.r() * 10), wick: 10 + p.r() * 8);
      p.bar(s(5 + p.r() * 5), wick: 5);
      break;
    case 'rejection-block':
      p.nBars(8 + (p.r() * 5).floor(), s(16 + p.r() * 12));
      p.bar(s(-18 - p.r() * 12), wick: 14 + p.r() * 8);
      p.bar(s(10 + p.r() * 8), wick: 6);
      p.chop(3 + (p.r() * 3).floor(), 7 + p.r() * 5);
      break;
    case 'structure':
      p.nBars(3 + (p.r() * 3).floor(), s(-14 - p.r() * 8));
      p.nBars(2 + (p.r() * 2).floor(), s(6 + p.r() * 4));
      p.nBars(3 + (p.r() * 3).floor(), s(-12 - p.r() * 8));
      p.nBars(2 + (p.r() * 2).floor(), s(7 + p.r() * 4));
      p.nBars(4 + (p.r() * 3).floor(), s(18 + p.r() * 12));
      break;
    case 'cisd':
      if (v < 0.33) {
        p.nBars(10 + (p.r() * 4).floor(), s(-30 - p.r() * 14));
        p.bar(s(14 + p.r() * 8), wick: 5);
      } else if (v < 0.66) {
        p.nBars(10 + (p.r() * 4).floor(), s(30 + p.r() * 14));
        p.bar(s(-14 - p.r() * 8), wick: 5);
      } else {
        p.nBars(7, s(-10 - p.r() * 8));
        p.nBars(7, s(10 + p.r() * 8));
      }
      break;
    case 'displacement':
      p.chop(8 + (p.r() * 8).floor(), 8 + p.r() * 8);
      p.nBars(3, s(36 + p.r() * 24), wick: 6);
      p.nBars(2, s(4 + p.r() * 6));
      break;
    case 'order-block':
      p.nBars(6 + (p.r() * 5).floor(), s(14 + p.r() * 10));
      p.bar(s(-10 - p.r() * 6), wick: 5);
      p.nBars(3 + (p.r() * 3).floor(), s(28 + p.r() * 16), wick: 6);
      p.nBars(3 + (p.r() * 3).floor(), s(-8 - p.r() * 6));
      break;
    case 'breaker-block':
      p.nBars(5 + (p.r() * 4).floor(), s(12 + p.r() * 10));
      p.bar(s(-8 - p.r() * 6), wick: 4);
      p.nBars(3, s(22 + p.r() * 12));
      p.nBars(4 + (p.r() * 3).floor(), s(-32 - p.r() * 16));
      if (v < 0.5) {
        p.nBars(3, s(16 + p.r() * 10));
      } else {
        p.chop(5, 10 + p.r() * 6);
      }
      break;
    case 'inducement':
      p.nBars(5 + (p.r() * 4).floor(), s(-12 - p.r() * 8));
      if (flip) {
        p.bearFvg(gap: 7 + p.r() * 8);
      } else {
        p.bullFvg(gap: 7 + p.r() * 8);
      }
      p.nBars(3, s(8 + p.r() * 6));
      p.nBars(4, s(-18 - p.r() * 10));
      p.chop(3, 7 + p.r() * 5);
      break;
    case 'unicorn':
      p.nBars(4 + (p.r() * 4).floor(), s(10 + p.r() * 10));
      p.bar(s(-9 - p.r() * 6), wick: 4);
      p.nBars(3, s(20 + p.r() * 10));
      p.nBars(3 + (p.r() * 3).floor(), s(-26 - p.r() * 12));
      p.nBars(3, s(14 + p.r() * 8));
      if (flip) {
        p.bearFvg(gap: 8 + p.r() * 8);
      } else {
        p.bullFvg(gap: 8 + p.r() * 8);
      }
      break;
    case 'premium-discount':
      p.nBars(5 + (p.r() * 4).floor(), s(40 + p.r() * 24));
      p.nBars(6 + (p.r() * 4).floor(), s(-20 - p.r() * 22));
      if (v < 0.45) p.chop(5, 10 + p.r() * 8);
      break;
    case 'daily-bias':
      p.chop(5 + (p.r() * 4).floor(), 7 + p.r() * 6);
      p.nBars(5, s(-18 - p.r() * 18));
      p.chop(4 + (p.r() * 4).floor(), 8 + p.r() * 6);
      break;
    case 'killzones':
      p.chop(6 + (p.r() * 5).floor(), 10 + p.r() * 8);
      p.nBars(5 + (p.r() * 3).floor(), s(12 + p.r() * 12));
      p.nBars(4, s(-16 - p.r() * 12));
      p.chop(3 + (p.r() * 3).floor(), 8 + p.r() * 6);
      break;
    case 'silver-bullet':
      p.chop(8 + (p.r() * 6).floor(), 8 + p.r() * 6);
      p.bar(s(-12 - p.r() * 8), wick: 6);
      if (flip) {
        p.bearFvg(gap: 8 + p.r() * 8);
      } else {
        p.bullFvg(gap: 8 + p.r() * 8);
      }
      p.nBars(2, s(3 + p.r() * 5));
      break;
    case 'mmxm':
      p.chop(6 + (p.r() * 5).floor(), 9 + p.r() * 8);
      p.nBars(6 + (p.r() * 4).floor(), s(-26 - p.r() * 16));
      p.chop(3 + (p.r() * 3).floor(), 7 + p.r() * 5);
      break;
    case 'po3':
      p.chop(6 + (p.r() * 5).floor(), 6 + p.r() * 5);
      p.nBars(5 + (p.r() * 3).floor(), s(-18 - p.r() * 14));
      p.chop(3, 5 + p.r() * 5);
      break;
    case 'judas':
      p.chop(8 + (p.r() * 6).floor(), 7 + p.r() * 6);
      p.nBars(3, s(-16 - p.r() * 16), wick: 8);
      break;
    case 'smt':
      p.nBars(5 + (p.r() * 4).floor(), s(10 + p.r() * 8));
      p.nBars(5, s(-14 - p.r() * 10));
      p.bar(s(-12 - p.r() * 8), wick: 8);
      p.chop(3 + (p.r() * 3).floor(), 6 + p.r() * 5);
      break;
    default:
      p.chop(6 + (p.r() * 5).floor(), 10 + p.r() * 8);
      p.nBars(6 + (p.r() * 4).floor(), s(16 + p.r() * 14));
      p.chop(3 + (p.r() * 3).floor(), 8 + p.r() * 6);
  }
  final minBars = 18 + (p.r() * 6).floor();
  final cap = 28 + (p.r() * 12).floor();
  if (p.out.length < minBars) p.chop(minBars - p.out.length, 8 + p.r() * 6);
  if (p.out.length > cap) {
    p.out.removeRange(0, p.out.length - cap);
  }
}

void _paintFuture(_Pen p, String id, QuizIntent intent) {
  final style = p.r();
  final stretch = 8 + p.r() * 18;
  switch (intent) {
    case QuizIntent.buy:
      if (style < 0.33) {
        p.nBars(3, id == 'judas' ? 4 : -(5 + p.r() * 8));
        p.nBars(5, 16 + stretch);
        p.nBars(6, 14 + p.r() * 16);
      } else if (style < 0.66) {
        p.nBars(4, 24 + stretch, wick: 6);
        p.nBars(8, 12 + p.r() * 14);
      } else {
        for (var i = 0; i < 4; i++) {
          p.nBars(2, 8 + p.r() * 6);
          p.nBars(2, -(2 + p.r() * 3));
        }
        p.nBars(4, 10 + p.r() * 10);
      }
      break;
    case QuizIntent.sell:
      if (style < 0.33) {
        p.nBars(3, id == 'judas' ? -4 : 5 + p.r() * 8);
        p.nBars(5, -(16 + stretch));
        p.nBars(6, -(14 + p.r() * 16));
      } else if (style < 0.66) {
        p.nBars(4, -(24 + stretch), wick: 6);
        p.nBars(8, -(12 + p.r() * 14));
      } else {
        for (var i = 0; i < 4; i++) {
          p.nBars(2, -(8 + p.r() * 6));
          p.nBars(2, 2 + p.r() * 3);
        }
        p.nBars(4, -(10 + p.r() * 10));
      }
      break;
    case QuizIntent.range:
      if (style < 0.34) {
        p.chop(14, 8 + p.r() * 8);
      } else if (style < 0.67) {
        p.nBars(3, 6 + p.r() * 5);
        p.nBars(3, -(6 + p.r() * 5));
        p.chop(8, 9 + p.r() * 5);
      } else {
        p.chop(6, 12 + p.r() * 6);
        p.nBars(2, 5 + p.r() * 4);
        p.nBars(2, -(5 + p.r() * 4));
        p.chop(6, 10 + p.r() * 5);
      }
      break;
  }
}

List<SmcMark> _marksFor(String id, List<SmcCandle> c, int freeze) {
  final marks = <SmcMark>[];
  switch (id) {
    case 'fvg':
    case 'ifvg':
    case 'bpr':
    case 'volume-imbalance':
    case 'unicorn':
    case 'silver-bullet':
      marks.addAll(_fvgMarks(c));
      break;
    case 'liquidity':
    case 'turtle-soup':
    case 'rejection-block':
    case 'smt':
      marks.addAll(_liqMarks(c, freeze));
      break;
    case 'structure':
    case 'cisd':
    case 'mmxm':
      marks.addAll(_swingMarks(c));
      break;
    case 'order-block':
    case 'breaker-block':
    case 'inducement':
      marks.addAll(_obMarks(c, freeze));
      marks.addAll(_fvgMarks(c));
      break;
    case 'displacement':
    case 'judas':
    case 'po3':
      marks.addAll(_dispMarks(c));
      marks.addAll(_fvgMarks(c));
      break;
    case 'premium-discount':
    case 'daily-bias':
      marks.addAll(_rangeMarks(c, freeze));
      break;
    case 'killzones':
      marks.addAll(_sessionMarks(c));
      break;
    default:
      marks.addAll(_fvgMarks(c));
      marks.addAll(_swingMarks(c));
  }
  return marks;
}

List<SmcMark> _fvgMarks(List<SmcCandle> c) {
  final out = <SmcMark>[];
  for (var i = 0; i + 2 < c.length && out.length < 2; i++) {
    if (c[i].high < c[i + 2].low) {
      out.add(SmcMark.box(
        i0: i,
        i1: i + 2,
        low: c[i].high,
        high: c[i + 2].low,
        label: 'Bull FVG',
        color: _g,
      ));
    } else if (c[i].low > c[i + 2].high) {
      out.add(SmcMark.box(
        i0: i,
        i1: i + 2,
        low: c[i + 2].high,
        high: c[i].low,
        label: 'Bear FVG',
        color: _r,
      ));
    }
  }
  return out;
}

List<SmcMark> _liqMarks(List<SmcCandle> c, int freeze) {
  var maxH = c.first.high;
  var minL = c.first.low;
  var hi = 0;
  var li = 0;
  for (var i = 0; i <= freeze && i < c.length; i++) {
    if (c[i].high >= maxH) {
      maxH = c[i].high;
      hi = i;
    }
    if (c[i].low <= minL) {
      minL = c[i].low;
      li = i;
    }
  }
  return [
    SmcMark.line(price: maxH, label: 'BSL', color: _r, i0: 0, i1: c.length - 1),
    SmcMark.line(price: minL, label: 'SSL', color: _g, i0: 0, i1: c.length - 1),
    SmcMark.tag(i0: hi, price: maxH, label: 'EQH', color: _r),
    SmcMark.tag(i0: li, price: minL, label: 'EQL', color: _g),
  ];
}

List<SmcMark> _swingMarks(List<SmcCandle> c) {
  final out = <SmcMark>[];
  for (var i = 2; i < c.length - 2; i++) {
    final h = c[i].high;
    if (h > c[i - 1].high && h > c[i - 2].high && h > c[i + 1].high && h > c[i + 2].high) {
      out.add(SmcMark.tag(i0: i, price: h, label: 'BOS H', color: _b));
    }
    final l = c[i].low;
    if (l < c[i - 1].low && l < c[i - 2].low && l < c[i + 1].low && l < c[i + 2].low) {
      out.add(SmcMark.tag(i0: i, price: l, label: 'SL', color: _o));
    }
  }
  return out.take(5).toList();
}

List<SmcMark> _obMarks(List<SmcCandle> c, int freeze) {
  for (var i = freeze - 1; i >= 2; i--) {
    final a = c[i];
    final b = c[i + 1];
    if (!a.bull && b.bull) {
      return [
        SmcMark.box(i0: i, i1: i, low: a.low, high: a.high, label: 'Bull OB', color: _g),
      ];
    }
    if (a.bull && !b.bull) {
      return [
        SmcMark.box(i0: i, i1: i, low: a.low, high: a.high, label: 'Bear OB', color: _r),
      ];
    }
  }
  return const [];
}

List<SmcMark> _dispMarks(List<SmcCandle> c) {
  var avg = 0.0;
  for (final x in c) {
    avg += x.high - x.low;
  }
  avg /= c.length;
  for (var i = 0; i < c.length; i++) {
    if (c[i].high - c[i].low > avg * 1.9) {
      return [
        SmcMark.tag(i0: i, price: c[i].high, label: 'Displacement', color: _p),
      ];
    }
  }
  return const [];
}

List<SmcMark> _rangeMarks(List<SmcCandle> c, int freeze) {
  var hi = c.first.high;
  var lo = c.first.low;
  for (var i = 0; i <= freeze; i++) {
    if (c[i].high > hi) hi = c[i].high;
    if (c[i].low < lo) lo = c[i].low;
  }
  final mid = (hi + lo) / 2;
  return [
    SmcMark.line(price: hi, label: 'Premium', color: _r, i0: 0, i1: c.length - 1),
    SmcMark.line(price: mid, label: 'EQ 50%', color: _o, i0: 0, i1: c.length - 1),
    SmcMark.line(price: lo, label: 'Discount', color: _g, i0: 0, i1: c.length - 1),
  ];
}

List<SmcMark> _sessionMarks(List<SmcCandle> c) {
  final a = (c.length * 0.15).floor();
  final b = (c.length * 0.42).floor();
  final d = (c.length * 0.72).floor();
  var lLo = c[a].low, lHi = c[a].high;
  for (var i = a; i <= b; i++) {
    if (c[i].low < lLo) lLo = c[i].low;
    if (c[i].high > lHi) lHi = c[i].high;
  }
  var nLo = c[b].low, nHi = c[b].high;
  for (var i = b; i <= d && i < c.length; i++) {
    if (c[i].low < nLo) nLo = c[i].low;
    if (c[i].high > nHi) nHi = c[i].high;
  }
  return [
    SmcMark.box(i0: a, i1: b, low: lLo, high: lHi, label: 'London', color: _b),
    SmcMark.box(i0: b, i1: d.clamp(0, c.length - 1), low: nLo, high: nHi, label: 'NY AM', color: _o),
  ];
}

String _prompt(String code) {
  return '$code on US100 15m — Read the tape. Next delivery: Buy, Sell, or Range?';
}

String _theory({
  required SmcTopic? topic,
  required QuizIntent intent,
  required double start,
  required double end,
}) {
  final pts = (end - start).abs();
  final tape = switch (intent) {
    QuizIntent.buy =>
      'From ${start.toStringAsFixed(2)} US100 expanded higher to ${end.toStringAsFixed(2)} (+${pts.toStringAsFixed(1)} pts). Trend won — Buy was the tape.',
    QuizIntent.sell =>
      'From ${start.toStringAsFixed(2)} US100 expanded lower to ${end.toStringAsFixed(2)} (−${pts.toStringAsFixed(1)} pts). Trend won — Sell was the tape.',
    QuizIntent.range =>
      'From ${start.toStringAsFixed(2)} US100 stayed inside a balance. Highs and lows overlapped — RANG was the tape, not a breakout.',
  };
  final body = topic == null
      ? ''
      : '\n\n${topic.title}: ${topic.what}\n\nHow to spot it: ${topic.spot}\n\nOn US100: ${topic.us100}';
  return '$tape$body\n\nMarks are drawn on this replay after the fact. Educational only — not a live signal.';
}

String quizRecordKey(String topicId, QuizIntent intent) => '${topicId}_${intent.name}';
