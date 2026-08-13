import 'package:flutter/material.dart';
import 'dart:math' as math;

class MobilePortfolio extends StatefulWidget {
  const MobilePortfolio({super.key});

  @override
  State<MobilePortfolio> createState() => _MobilePortfolioState();
}

class _MobilePortfolioState extends State<MobilePortfolio> {
  String _selectedPeriod = '30D';
  final List<String> _periods = ['1D', '7D', '30D', '90D', 'All'];

  static const Color cardColor = Color(0xFF141824);
  static const Color borderColor = Color(0x1AFFFFFF);

  @override
  Widget build(BuildContext context) {
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
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: selected
                                ? const Color(0xFF3B82F6)
                                : borderColor),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[400],
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
                              values: const [32, 16, 0],
                              colors: const [
                                Color(0xFF22C55E),
                                Color(0xFFEF4444),
                                Color(0xFF6B7280)
                              ],
                              strokeWidth: 16,
                            ),
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('48',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text('Total Trades',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10)),
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
                          _legendRow('Profitable Trades', '32', '(66.7%)',
                              const Color(0xFF22C55E)),
                          const SizedBox(height: 12),
                          _legendRow('Losing Trades', '16', '(33.3%)',
                              const Color(0xFFEF4444)),
                          const SizedBox(height: 12),
                          _legendRow('Break-even', '0', '(0%)',
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
                        child: _summaryTile('Win Rate', '66.7%', Colors.white,
                            '8.5%', true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _summaryTile('Best Trade', '+\$1,256.32',
                            const Color(0xFF22C55E), '12.3%', true)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _summaryTile('Worst Trade', '-\$512.45',
                            const Color(0xFFEF4444), '6.2%', false)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _summaryTile('Avg Trade', '+\$132.45',
                            const Color(0xFF22C55E), '8.1%', true)),
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
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('P&L',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey[400], size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('+\$6,356.72',
                    style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: LineAreaChartPainter(
                      values: const [
                        1200,
                        2100,
                        1800,
                        3200,
                        2800,
                        4100,
                        3600,
                        4800,
                        5200,
                        4700,
                        5800,
                        6356.72
                      ],
                      lineColor: const Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['May 1', 'May 8', 'May 15', 'May 22', 'May 29']
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
                              values: const [28, 20],
                              colors: const [
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899)
                              ],
                              strokeWidth: 16,
                            ),
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('48',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text('Total Trades',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10)),
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
                          _legendRow('Long Trades', '28', '(58.3%)',
                              const Color(0xFF8B5CF6)),
                          const SizedBox(height: 12),
                          _legendRow('Short Trades', '20', '(41.7%)',
                              const Color(0xFFEC4899)),
                          const SizedBox(height: 12),
                          _legendRow('Total Trades', '48', '',
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
                    const Text('Recent Trades',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('View All',
                        style:
                        TextStyle(color: Colors.blue[400], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                _tradeItem('BTC/USDT', 'Long', 'May 29, 2024 · 10:35 AM',
                    '+\$485.32', '+2.45%', true, const Color(0xFFF97316)),
                const Divider(color: Colors.white10, height: 20),
                _tradeItem('ETH/USDT', 'Short', 'May 29, 2024 · 09:15 AM',
                    '-\$123.45', '-1.25%', false, const Color(0xFF6366F1)),
                const Divider(color: Colors.white10, height: 20),
                _tradeItem('SOL/USDT', 'Long', 'May 28, 2024 · 04:20 PM',
                    '+\$256.78', '+2.12%', true, const Color(0xFF14B8A6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helper widgets ----------
  Widget _cardWrapper({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.info_outline, color: Colors.grey[600], size: 14),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _legendRow(String label, String value, String percent, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text(percent, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Widget _summaryTile(
      String label, String value, Color valueColor, String delta, bool isUp) {
    final deltaColor =
    isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
      String pct, bool isUp, Color iconColor) {
    final sideColor =
    side == 'Long' ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final valueColor =
    isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Row(
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
                      style: const TextStyle(
                          color: Colors.white,
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
        const Text('Portfolio',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('Your trading performance',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
    if (total <= 0) return;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
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