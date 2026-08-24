import 'package:flutter/material.dart';

import '../service/demo_trade_service.dart';
import '../service/us100_quote_service.dart';

/// Draws open-price (blue), SL (red) and TP (green) across the trade chart.
class TradeLevelsOverlay extends StatelessWidget {
  const TradeLevelsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = DemoTradeService.instance;
    final quotes = Us100QuoteService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([demo, quotes]),
      builder: (context, _) {
        if (demo.positions.isEmpty) return const SizedBox.shrink();
        return IgnorePointer(
          child: CustomPaint(
            painter: _LevelsPainter(
              positions: List<DemoPosition>.from(demo.positions),
              bid: quotes.bid,
              ask: quotes.ask,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _LevelsPainter extends CustomPainter {
  final List<DemoPosition> positions;
  final double bid;
  final double ask;

  _LevelsPainter({
    required this.positions,
    required this.bid,
    required this.ask,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final prices = <double>[bid, ask];
    for (final p in positions) {
      prices.add(p.openPrice);
      if (p.sl != null) prices.add(p.sl!);
      if (p.tp != null) prices.add(p.tp!);
    }
    var minP = prices.reduce((a, b) => a < b ? a : b);
    var maxP = prices.reduce((a, b) => a > b ? a : b);
    if (maxP - minP < 4) {
      final mid = (maxP + minP) / 2;
      minP = mid - 8;
      maxP = mid + 8;
    } else {
      final pad = (maxP - minP) * 0.18;
      minP -= pad;
      maxP += pad;
    }

    double yOf(double price) {
      final t = (price - minP) / (maxP - minP);
      return size.height * (1 - t.clamp(0.0, 1.0));
    }

    for (final p in positions.reversed) {
      _line(
        canvas,
        size,
        yOf(p.openPrice),
        const Color(0xFF3B82F6),
        'OPEN ${p.openPrice.toStringAsFixed(2)}  ${p.side}',
      );
      if (p.sl != null) {
        _line(
          canvas,
          size,
          yOf(p.sl!),
          const Color(0xFFEF4444),
          'SL ${p.sl!.toStringAsFixed(2)}',
        );
      }
      if (p.tp != null) {
        _line(
          canvas,
          size,
          yOf(p.tp!),
          const Color(0xFF22C55E),
          'TP ${p.tp!.toStringAsFixed(2)}',
        );
      }
    }
  }

  void _line(Canvas canvas, Size size, double y, Color color, String label) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    const dash = 7.0;
    const gap = 5.0;
    var x = 0.0;
    while (x < size.width - 78) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width - 78), y), paint);
      x += dash + gap;
    }
    final tag = Paint()..color = color;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 76, y - 9, 74, 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, tag);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 70);
    tp.paint(canvas, Offset(size.width - 73, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _LevelsPainter oldDelegate) {
    return oldDelegate.bid != bid ||
        oldDelegate.ask != ask ||
        oldDelegate.positions.length != positions.length ||
        oldDelegate.positions.map((p) => '${p.id}${p.sl}${p.tp}${p.openPrice}').join() !=
            positions.map((p) => '${p.id}${p.sl}${p.tp}${p.openPrice}').join();
  }
}
