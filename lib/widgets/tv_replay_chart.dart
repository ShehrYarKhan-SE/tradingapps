import 'dart:math';

import 'package:flutter/material.dart';

import '../content/smc/smc_models.dart';
import '../content/smc/smc_quiz_engine.dart';

const _tvBg = Color(0xFF131722);
const _tvGrid = Color(0xFF1E222D);
const _tvBull = Color(0xFF26A69A);
const _tvBear = Color(0xFFEF5350);
const _tvMuted = Color(0xFF787B86);
const _tvText = Color(0xFFD1D4DC);
const _tvCross = Color(0xFF9598A1);

class TvReplayChart extends StatelessWidget {
  const TvReplayChart({
    super.key,
    required this.candles,
    required this.visibleCount,
    this.marks = const [],
    this.nowIndex,
    this.entryIndex,
    this.entryPick,
    this.height = 340,
    this.badge = '15',
  });

  final List<SmcCandle> candles;
  final int visibleCount;
  final List<SmcMark> marks;
  final int? nowIndex;
  final int? entryIndex;
  final QuizIntent? entryPick;
  final double height;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final vis = visibleCount.clamp(0, candles.length);
    final last = vis > 0 ? candles[vis - 1] : null;
    final first = vis > 0 ? candles[0] : null;
    final chg = (last != null && first != null) ? last.close - first.open : 0.0;
    final chgPct = (first != null && first.open != 0) ? chg / first.open * 100 : 0.0;
    final up = chg >= 0;
    return Container(
      decoration: BoxDecoration(
        color: _tvBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                const Text(
                  'US100',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  badge,
                  style: const TextStyle(color: _tvMuted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(width: 10),
                if (last != null)
                  Expanded(
                    child: Text(
                      'O ${last.open.toStringAsFixed(1)}  H ${last.high.toStringAsFixed(1)}  L ${last.low.toStringAsFixed(1)}  C ${last.close.toStringAsFixed(1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _tvText, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                Text(
                  '${up ? '+' : ''}${chg.toStringAsFixed(1)} (${up ? '+' : ''}${chgPct.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: up ? _tvBull : _tvBear,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _TvPainter(
                candles: candles,
                marks: marks,
                visibleCount: vis,
                nowIndex: nowIndex,
                entryIndex: entryIndex,
                entryPick: entryPick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TvPainter extends CustomPainter {
  _TvPainter({
    required this.candles,
    required this.marks,
    required this.visibleCount,
    this.nowIndex,
    this.entryIndex,
    this.entryPick,
  });

  final List<SmcCandle> candles;
  final List<SmcMark> marks;
  final int visibleCount;
  final int? nowIndex;
  final int? entryIndex;
  final QuizIntent? entryPick;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || visibleCount <= 0) return;
    final vis = candles.take(visibleCount).toList();
    const padL = 8.0;
    const padR = 52.0;
    const padT = 8.0;
    const volH = 52.0;
    const padB = 18.0;
    final priceH = size.height - padT - volH - padB;
    final w = size.width - padL - padR;
    final slots = max(1, candles.length);

    var minP = vis.first.low;
    var maxP = vis.first.high;
    for (final c in vis) {
      minP = min(minP, c.low);
      maxP = max(maxP, c.high);
    }
    final span = max(8.0, maxP - minP);
    minP -= span * 0.06;
    maxP += span * 0.08;

    double xOf(int i) => padL + (w / slots) * (i + 0.5);
    double leftOf(int i) => padL + (w / slots) * i;
    double rightOf(int i) => padL + (w / slots) * (i + 1);
    double yOf(double p) => padT + (maxP - p) / (maxP - minP) * priceH;

    canvas.drawRect(Offset.zero & size, Paint()..color = _tvBg);

    _watermark(canvas, size);

    final step = _nice(span / 5);
    var tick = (minP / step).floor() * step;
    final grid = Paint()
      ..color = _tvGrid
      ..strokeWidth = 1;
    while (tick <= maxP) {
      final y = yOf(tick);
      canvas.drawLine(Offset(padL, y), Offset(padL + w, y), grid);
      _axisLabel(canvas, padL + w + 6, y - 6, tick.toStringAsFixed(tick >= 1000 ? 1 : 2));
      tick += step;
    }

    canvas.drawLine(
      Offset(padL + w, padT),
      Offset(padL + w, padT + priceH),
      Paint()
        ..color = const Color(0xFF2A2E39)
        ..strokeWidth = 1,
    );

    if (visibleCount < candles.length) {
      canvas.drawRect(
        Rect.fromLTRB(leftOf(visibleCount), padT, padL + w, padT + priceH),
        Paint()..color = Colors.white.withValues(alpha: 0.025),
      );
    }

    for (final m in marks) {
      if (m.kind != SmcMarkKind.box) continue;
      final i0 = m.i0.clamp(0, vis.length - 1);
      final i1 = (m.i1 < 0 ? vis.length - 1 : m.i1).clamp(0, vis.length - 1);
      if (min(i0, i1) >= visibleCount) continue;
      final rect = Rect.fromLTRB(
        leftOf(min(i0, i1)),
        yOf(max(m.low, m.high)),
        rightOf(max(i0, i1).clamp(0, visibleCount - 1)),
        yOf(min(m.low, m.high)),
      );
      canvas.drawRect(rect, Paint()..color = m.color.withValues(alpha: 0.14));
      canvas.drawRect(
        rect,
        Paint()
          ..color = m.color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      _tag(canvas, rect.left + 3, rect.top + 2, m.label, m.color);
    }

    for (final m in marks) {
      if (m.kind != SmcMarkKind.line) continue;
      final y = yOf(m.price);
      final i1 = (m.i1 < 0 ? visibleCount - 1 : m.i1).clamp(0, visibleCount - 1);
      _dash(
        canvas,
        Offset(leftOf(m.i0.clamp(0, vis.length - 1)), y),
        Offset(rightOf(i1), y),
        Paint()
          ..color = m.color.withValues(alpha: 0.85)
          ..strokeWidth = 1,
      );
      _tag(canvas, leftOf(m.i0.clamp(0, vis.length - 1)) + 2, y - 13, m.label, m.color);
    }

    _ema(canvas, vis, slots, w, padL, yOf);

    var maxVol = 1.0;
    for (final c in vis) {
      final v = c.high - c.low;
      if (v > maxVol) maxVol = v;
    }
    final volTop = padT + priceH + 6;
    final bodyW = max(2.6, (w / slots) * 0.62);
    for (var i = 0; i < vis.length; i++) {
      final c = vis[i];
      final x = xOf(i);
      final color = c.bull ? _tvBull : _tvBear;
      canvas.drawLine(
        Offset(x, yOf(c.high)),
        Offset(x, yOf(c.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1.15
          ..strokeCap = StrokeCap.round,
      );
      final top = yOf(max(c.open, c.close));
      final bot = yOf(min(c.open, c.close));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, (top + bot) / 2),
            width: bodyW,
            height: max(1.6, bot - top),
          ),
          const Radius.circular(0.6),
        ),
        Paint()..color = color,
      );
      final vh = ((c.high - c.low) / maxVol) * (volH - 10);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, volTop + (volH - 10) - vh / 2),
          width: bodyW,
          height: max(1, vh),
        ),
        Paint()..color = color.withValues(alpha: 0.45),
      );
    }

    for (final m in marks) {
      if (m.kind != SmcMarkKind.tag) continue;
      if (m.i0 >= visibleCount) continue;
      _tag(canvas, xOf(m.i0.clamp(0, vis.length - 1)) - 8, yOf(m.price) - 12, m.label, m.color);
    }

    if (nowIndex != null && nowIndex! < visibleCount) {
      final x = xOf(nowIndex!);
      _dash(
        canvas,
        Offset(x, padT),
        Offset(x, padT + priceH),
        Paint()
          ..color = _tvCross
          ..strokeWidth = 1,
      );
    }

    if (entryIndex != null && entryPick != null && entryIndex! < visibleCount) {
      final i = entryIndex!.clamp(0, vis.length - 1);
      final x = xOf(i);
      final y = yOf(vis[i].close);
      final col = entryPick!.color;
      final path = Path();
      if (entryPick == QuizIntent.sell) {
        path
          ..moveTo(x, y - 7)
          ..lineTo(x - 7, y - 18)
          ..lineTo(x + 7, y - 18)
          ..close();
      } else if (entryPick == QuizIntent.buy) {
        path
          ..moveTo(x, y + 7)
          ..lineTo(x - 7, y + 18)
          ..lineTo(x + 7, y + 18)
          ..close();
      } else {
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = col);
      }
      if (entryPick != QuizIntent.range) {
        canvas.drawPath(path, Paint()..color = col);
      }
      _tag(canvas, x + 8, y - 10, entryPick!.short, col);
    }

    final last = vis.last.close;
    final ly = yOf(last);
    final lastCol = vis.last.bull ? _tvBull : _tvBear;
    canvas.drawLine(
      Offset(xOf(vis.length - 1), ly),
      Offset(size.width - 4, ly),
      Paint()
        ..color = lastCol.withValues(alpha: 0.7)
        ..strokeWidth = 1,
    );
    final tag = last.toStringAsFixed(1);
    final tp = TextPainter(
      text: TextSpan(
        text: tag,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - padR + 2, ly - 8, padR - 6, 16),
      const Radius.circular(3),
    );
    canvas.drawRRect(rr, Paint()..color = lastCol);
    tp.paint(canvas, Offset(size.width - padR + 6, ly - 7));

    if (vis.first.time != null && vis.last.time != null) {
      _axisLabel(
        canvas,
        padL,
        size.height - 14,
        _fmt(vis.first.time!),
      );
      _axisLabel(
        canvas,
        padL + w - 40,
        size.height - 14,
        _fmt(vis.last.time!),
      );
    }
  }

  void _ema(
    Canvas canvas,
    List<SmcCandle> vis,
    int slots,
    double w,
    double padL,
    double Function(double) yOf,
  ) {
    if (vis.length < 5) return;
    const n = 9;
    var ema = vis.first.close;
    const k = 2 / (n + 1);
    final path = Path();
    for (var i = 0; i < vis.length; i++) {
      ema = vis[i].close * k + ema * (1 - k);
      final x = padL + (w / slots) * (i + 0.5);
      final y = yOf(ema);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2962FF).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
    );
  }

  void _watermark(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'US100',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.05),
          fontSize: 64,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.18, size.height * 0.28));
  }

  double _nice(double raw) {
    if (raw <= 5) return 5;
    if (raw <= 10) return 10;
    if (raw <= 20) return 20;
    if (raw <= 25) return 25;
    if (raw <= 50) return 50;
    if (raw <= 100) return 100;
    return 200;
  }

  String _fmt(DateTime t) {
    final l = t.toLocal();
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    final d = (b - a).distance;
    if (d == 0) return;
    final dir = (b - a) / d;
    var t = 0.0;
    while (t < d) {
      final n = min(dash, d - t);
      canvas.drawLine(a + dir * t, a + dir * (t + n), paint);
      t += dash + gap;
    }
  }

  void _tag(Canvas canvas, double x, double y, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, tp.width + 8, tp.height + 3),
      const Radius.circular(3),
    );
    canvas.drawRRect(bg, Paint()..color = const Color(0xEE131722));
    canvas.drawRRect(
      bg,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(x + 4, y + 1.5));
  }

  void _axisLabel(Canvas canvas, double x, double y, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: _tvMuted, fontSize: 9, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _TvPainter oldDelegate) {
    return oldDelegate.visibleCount != visibleCount ||
        oldDelegate.candles != candles ||
        oldDelegate.marks != marks ||
        oldDelegate.entryIndex != entryIndex ||
        oldDelegate.entryPick != entryPick ||
        oldDelegate.nowIndex != nowIndex;
  }
}
