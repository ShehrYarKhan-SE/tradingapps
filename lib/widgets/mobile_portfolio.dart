import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../service/demo_trade_service.dart';
import '../service/us100_quote_service.dart';
import '../theme_controller.dart';

class MobilePortfolio extends StatefulWidget {
  const MobilePortfolio({super.key});

  @override
  State<MobilePortfolio> createState() => _MobilePortfolioState();
}

class _MobilePortfolioState extends State<MobilePortfolio> {
  String _selectedPeriod = '30D';
  final List<String> _periods = ['1D', '7D', '30D', '90D', 'All'];

  AppColors get _colors => AppColors.of(context);

  @override
  void initState() {
    super.initState();
    DemoTradeService.instance.init();
    DemoTradeService.instance.addListener(_onDemo);
    Us100QuoteService.instance.attach();
    Us100QuoteService.instance.addListener(_onDemo);
  }

  @override
  void dispose() {
    DemoTradeService.instance.removeListener(_onDemo);
    Us100QuoteService.instance.removeListener(_onDemo);
    Us100QuoteService.instance.detach();
    super.dispose();
  }

  void _onDemo() {
    if (mounted) setState(() {});
  }

  String _formatTradeTime(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '${months[t.month - 1]} ${t.day}, ${t.year} · $h:$m $ampm';
  }

  Duration? _periodSpan() {
    switch (_selectedPeriod) {
      case '1D':
        return const Duration(days: 1);
      case '7D':
        return const Duration(days: 7);
      case '30D':
        return const Duration(days: 30);
      case '90D':
        return const Duration(days: 90);
      default:
        return null;
    }
  }

  List<DemoTrade> _tradesInPeriod() {
    final all = DemoTradeService.instance.trades;
    final span = _periodSpan();
    if (span == null) return List<DemoTrade>.from(all);
    final start = DateTime.now().subtract(span);
    return all.where((t) => !t.closeTime.isBefore(start)).toList();
  }

  String _pct(num part, num total) {
    if (total <= 0) return '(0%)';
    return '(${(part / total * 100).toStringAsFixed(1)}%)';
  }

  String _signedMoney(double v) {
    if (v > 0) return '+\$${v.toStringAsFixed(2)}';
    if (v < 0) return '-\$${v.abs().toStringAsFixed(2)}';
    return '\$0.00';
  }

  String _axisDate(DateTime t) => '${t.month}/${t.day}';

  List<String> _axisLabels(List<DemoTrade> ordered) {
    if (ordered.isEmpty) return const ['—', '—', '—', '—', '—'];
    final first = ordered.first.closeTime;
    final last = ordered.last.closeTime;
    if (ordered.length == 1 || last.isAtSameMomentAs(first)) {
      final d = _axisDate(first);
      return [d, d, d, d, d];
    }
    return List.generate(5, (i) {
      final t = first.add(Duration(
        milliseconds:
            (last.difference(first).inMilliseconds * i / 4).round(),
      ));
      return _axisDate(t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final demo = DemoTradeService.instance;
    final quotes = Us100QuoteService.instance;
    final closed = _tradesInPeriod();
    final wins = closed.where((t) => t.pnl > 0.005).length;
    final losses = closed.where((t) => t.pnl < -0.005).length;
    final be = closed.length - wins - losses;
    final total = closed.length;
    final realized = closed.fold<double>(0, (a, t) => a + t.pnl);
    final floating = quotes.hasQuote
        ? demo.positions.fold<double>(
            0, (a, p) => a + p.pnl(quotes.bid, quotes.ask))
        : 0.0;
    DemoTrade? best;
    DemoTrade? worst;
    for (final t in closed) {
      if (best == null || t.pnl > best.pnl) best = t;
      if (worst == null || t.pnl < worst.pnl) worst = t;
    }
    final avg = total == 0 ? 0.0 : realized / total;
    final winRate = total == 0 ? 0.0 : wins * 100 / total;
    final longs = closed.where((t) => t.side == 'BUY').length;
    final shorts = closed.where((t) => t.side == 'SELL').length;
    final chronological = List<DemoTrade>.from(closed)
      ..sort((a, b) => a.closeTime.compareTo(b.closeTime));
    final curve = <double>[0];
    var run = 0.0;
    for (final t in chronological) {
      run += t.pnl;
      curve.add(run);
    }
    final axisLabels = chronological.isEmpty
        ? const ['—', '—', '—', '—', '—']
        : _axisLabels(chronological);
    final pnlColor =
        realized >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final shownTrades = closed.take(8).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _PortfolioTitle(),
          ),
          const SizedBox(height: 16),

          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _periods.map((p) {
                final selected = p == _selectedPeriod;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF3B82F6)
                            : _colors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: selected
                                ? const Color(0xFF3B82F6)
                                : _colors.border),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: selected ? Colors.white : _colors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Performance Overview
          _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader('Performance Overview'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(130, 130),
                            painter: DonutChartPainter(
                              values: [
                                wins.toDouble(),
                                losses.toDouble(),
                                be.toDouble(),
                              ],
                              colors: const [
                                Color(0xFF22C55E),
                                Color(0xFFEF4444),
                                Color(0xFF6B7280)
                              ],
                              strokeWidth: 16,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$total',
                                  style: TextStyle(
                                      color: _colors.text,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text('Total Trades',
                                  style: TextStyle(
                                      color: _colors.muted, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendRow('Profitable Trades', '$wins', _pct(wins, total),
                              const Color(0xFF22C55E)),
                          const SizedBox(height: 12),
                          _legendRow('Losing Trades', '$losses', _pct(losses, total),
                              const Color(0xFFEF4444)),
                          const SizedBox(height: 12),
                          _legendRow('Break-even', '$be', _pct(be, total),
                              const Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Performance Summary
          _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader('Performance Summary'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _summaryTile(
                            'Win Rate',
                            '${winRate.toStringAsFixed(1)}%',
                            _colors.text,
                            '$wins / $total',
                            winRate >= 50)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _summaryTile(
                            'Best Trade',
                            best == null ? '\$0.00' : _signedMoney(best.pnl),
                            const Color(0xFF22C55E),
                            best?.symbol ?? '—',
                            true)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _summaryTile(
                            'Worst Trade',
                            worst == null ? '\$0.00' : _signedMoney(worst.pnl),
                            const Color(0xFFEF4444),
                            worst?.symbol ?? '—',
                            false)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _summaryTile(
                            'Avg Trade',
                            _signedMoney(avg),
                            avg >= 0
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            '$total closed',
                            avg >= 0)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // P&L Overview
          _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(
                  'P&L Overview',
                  trailing: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _colors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('P&L',
                            style: TextStyle(
                                color: _colors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey[400], size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_signedMoney(realized),
                    style: TextStyle(
                        color: pnlColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                if (demo.positions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Open P&L ${_signedMoney(floating)}  ·  Balance \$${demo.balance.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: LineAreaChartPainter(
                      values: curve,
                      lineColor: pnlColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: axisLabels
                      .map((e) => Text(e,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 10)))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Trade Breakdown
          _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader('Trade Breakdown'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(130, 130),
                            painter: DonutChartPainter(
                              values: [
                                longs.toDouble(),
                                shorts.toDouble(),
                              ],
                              colors: const [
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899)
                              ],
                              strokeWidth: 16,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$total',
                                  style: TextStyle(
                                      color: _colors.text,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text('Total Trades',
                                  style: TextStyle(
                                      color: _colors.muted, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendRow('Long Trades', '$longs', _pct(longs, total),
                              const Color(0xFF8B5CF6)),
                          const SizedBox(height: 12),
                          _legendRow('Short Trades', '$shorts', _pct(shorts, total),
                              const Color(0xFFEC4899)),
                          const SizedBox(height: 12),
                          _legendRow('Total Trades', '$total', '',
                              const Color(0xFF3B82F6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent Trades
          _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Trades',
                        style: TextStyle(
                            color: _colors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('View All',
                        style:
                        TextStyle(color: Colors.blue[400], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    if (shownTrades.isEmpty) {
                      return Text(
                        'No closed trades in this period. Open the Trade tab to buy or sell.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      );
                    }
                    final rows = <Widget>[];
                    for (var i = 0; i < shownTrades.length; i++) {
                      final t = shownTrades[i];
                      if (i > 0) {
                        rows.add(Divider(color: _colors.border, height: 20));
                      }
                      rows.add(_tradeItem(
                        t.symbol,
                        t.side == 'BUY' ? 'Buy' : 'Sell',
                        _formatTradeTime(t.closeTime),
                        _signedMoney(t.pnl),
                        '${t.lots.toStringAsFixed(2)} lot · ${t.openPrice.toStringAsFixed(2)}→${t.closePrice.toStringAsFixed(2)}',
                        t.pnl >= 0,
                        t.side == 'BUY' ? const Color(0xFF1E88E5) : const Color(0xFFE53935),
                        review: t.review,
                      ));
                    }
                    return Column(children: rows);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helper widgets ----------
  Widget _cardWrapper({required Widget child}) {
    final colors = _colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, {Widget? trailing}) {
    final colors = _colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title,
                style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.info_outline, color: colors.muted, size: 14),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _legendRow(String label, String value, String percent, Color color) {
    final colors = _colors;
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(color: colors.muted, fontSize: 12))),
        Text(value,
            style: TextStyle(
                color: colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text(percent, style: TextStyle(color: colors.muted, fontSize: 11)),
      ],
    );
  }

  Widget _summaryTile(
      String label, String value, Color valueColor, String delta, bool isUp) {
    final colors = _colors;
    final deltaColor =
    isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: deltaColor, size: 11),
              const SizedBox(width: 2),
              Text(delta,
                  style: TextStyle(
                      color: deltaColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tradeItem(String symbol, String side, String time, String amount,
      String pct, bool isUp, Color iconColor, {String? review}) {
    final sideColor =
    (side == 'Long' || side == 'Buy') ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final valueColor =
    isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2), shape: BoxShape.circle),
          child: Center(
            child: Text(symbol[0],
                style:
                TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(symbol,
                      style: TextStyle(
                          color: _colors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: sideColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(side,
                        style: TextStyle(
                            color: sideColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount,
                style: TextStyle(
                    color: valueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text(pct, style: TextStyle(color: valueColor, fontSize: 11)),
          ],
        ),
      ],
    ),
        if (review != null && review.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            review,
            style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 11, height: 1.35),
          ),
        ],
      ],
    );
  }
}

class _PortfolioTitle extends StatelessWidget {
  const _PortfolioTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portfolio',
            style: TextStyle(
                color: AppColors.of(context).text,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('Your trading performance',
            style: TextStyle(color: AppColors.of(context).muted, fontSize: 13)),
      ],
    );
  }
}

// ---------------- Painters ----------------

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  DonutChartPainter(
      {required this.values, required this.colors, this.strokeWidth = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF374151)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }
    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      if (values[i] <= 0) continue;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.03,
        sweep - 0.06,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}

class LineAreaChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  LineAreaChartPainter({required this.values, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    if (values.length == 1) {
      final y = size.height * 0.45;
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      canvas.drawCircle(Offset(size.width, y), 4, Paint()..color = lineColor);
      return;
    }
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = dx * i;
      final normalized = (values[i] - minV) / range;
      final y = size.height - (normalized * size.height * 0.85) - 8;
      points.add(Offset(x, y));
    }

    // Area fill
    final areaPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.35), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Dot at end
    canvas.drawCircle(points.last, 4, Paint()..color = lineColor);
    canvas.drawCircle(
        points.last,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant LineAreaChartPainter oldDelegate) => true;
}