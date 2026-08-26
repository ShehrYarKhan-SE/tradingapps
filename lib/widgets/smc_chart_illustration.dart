import 'dart:math';

import 'package:flutter/material.dart';

import '../content/smc/smc_models.dart';

class SmcChartCard extends StatelessWidget {
  const SmcChartCard({super.key, required this.chart});

  final SmcChart chart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Text(
                  'US100',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chart.timeframe,
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Educational example',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 210,
            width: double.infinity,
            child: CustomPaint(
              painter: _SmcChartPainter(chart),
            ),
          ),
          if (chart.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                chart.caption,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmcChartPainter extends CustomPainter {
  _SmcChartPainter(this.chart);

  final SmcChart chart;

  @override
  void paint(Canvas canvas, Size size) {
    final candles = chart.candles;
    if (candles.isEmpty) return;

    const padL = 10.0;
    const padR = 10.0;
    const padT = 18.0;
    const padB = 16.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    var minP = candles.first.low;
    var maxP = candles.first.high;
    for (final c in candles) {
      minP = min(minP, c.low);
      maxP = max(maxP, c.high);
    }
    final span = max(1.0, maxP - minP);
    minP -= span * 0.08;
    maxP += span * 0.12;

    double xOf(int i) {
      final step = w / max(1, candles.length);
      return padL + step * (i + 0.5);
    }

    double yOf(double p) => padT + (maxP - p) / (maxP - minP) * h;

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = padT + h * i / 3;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), grid);
    }

    double leftOf(int i) {
      final step = w / candles.length;
      return padL + step * i;
    }

    double rightOf(int i) {
      final step = w / candles.length;
      return padL + step * (i + 1);
    }

    for (final m in chart.marks) {
      if (m.kind != SmcMarkKind.box) continue;
      final i0 = m.i0.clamp(0, candles.length - 1);
      final i1 = (m.i1 < 0 ? candles.length - 1 : m.i1).clamp(0, candles.length - 1);
      final rect = Rect.fromLTRB(
        leftOf(min(i0, i1)),
        yOf(max(m.low, m.high)),
        rightOf(max(i0, i1)),
        yOf(min(m.low, m.high)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = m.color.withValues(alpha: 0.18),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = m.color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      _label(canvas, rect.left + 4, rect.top + 2, m.label, m.color);
    }

    for (final m in chart.marks) {
      if (m.kind != SmcMarkKind.line) continue;
      final i0 = m.i0.clamp(0, candles.length - 1);
      final i1 = m.i1 < 0 ? candles.length - 1 : m.i1.clamp(0, candles.length - 1);
      final y = yOf(m.price);
      final paint = Paint()
        ..color = m.color.withValues(alpha: 0.85)
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke;
      _dash(canvas, Offset(leftOf(i0), y), Offset(rightOf(i1), y), paint);
      _label(canvas, leftOf(i0) + 2, y - 14, m.label, m.color);
    }

    final step = w / candles.length;
    final bodyW = max(3.0, step * 0.55);
    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = xOf(i);
      final color = c.bull ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      final wick = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, yOf(c.high)), Offset(x, yOf(c.low)), wick);
      final top = yOf(max(c.open, c.close));
      final bot = yOf(min(c.open, c.close));
      final bodyH = max(2.0, bot - top);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, (top + bot) / 2), width: bodyW, height: bodyH),
          const Radius.circular(1.5),
        ),
        Paint()..color = color,
      );
    }

    for (final m in chart.marks) {
      if (m.kind != SmcMarkKind.tag) continue;
      final i = m.i0.clamp(0, candles.length - 1);
      _label(canvas, xOf(i) - 10, yOf(m.price) - 12, m.label, m.color);
    }
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
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

  void _label(Canvas canvas, double x, double y, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, tp.width + 8, tp.height + 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(bg, Paint()..color = const Color(0xEE0B1224));
    canvas.drawRRect(
      bg,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(x + 4, y + 2));
  }

  @override
  bool shouldRepaint(covariant _SmcChartPainter oldDelegate) => oldDelegate.chart != chart;
}
