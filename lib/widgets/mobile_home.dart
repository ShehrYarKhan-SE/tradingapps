import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/learning_path_screen.dart';
import '../screens/profile_screen.dart';
import '../service/ai_learning_store.dart';
import '../service/home_trending_quotes.dart';
import '../service/user_account_store.dart';

class MobileHome extends StatelessWidget {
  final Function(String) onTabChange;
  final void Function(String symbol) onOpenChart;

  const MobileHome({
    super.key,
    required this.onTabChange,
    required this.onOpenChart,
  });

  Future<File?> _loadProfileImage() async {
    final savedPath = await UserAccountStore.instance.loadProfileImagePath();
    if (savedPath != null && File(savedPath).existsSync()) {
      return File(savedPath);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ---------------- Profile (home page only, scrolls away) ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: FutureBuilder<File?>(
                          future: _loadProfileImage(),
                          builder: (context, snapshot) {
                            final imageFile = snapshot.data;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1A1A1F),
                                image: imageFile != null
                                    ? DecorationImage(
                                  image: FileImage(imageFile),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: imageFile == null
                                  ? Icon(Icons.person, color: Colors.grey[400], size: 17)
                                  : null,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0D0D0F), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FirebaseAuth.instance.currentUser?.displayName ?? "User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.purple[400],
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, color: Colors.yellow, size: 11),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---------------- Welcome Card ----------------
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1229), Color(0xFF13214A), Color(0xFF1B1450)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Decorative target + bar-chart graphic (approximates the artwork)
                Positioned(
                  right: -6,
                  top: -10,
                  child: _buildTargetGraphic(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Trader!',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to practice?',
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trade with virtual money,\nlearn with real confidence.',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onTabChange('trade'),
                            child: _buildCardButton(
                              'Demo Mode',
                              Icons.bolt,
                              const Color(0xFF10B981).withOpacity(0.45),
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onTabChange('coach'),
                            child: _buildCardButton(
                              'AI Coach',
                              Icons.smart_toy_outlined,
                              const Color(0xFF8B5CF6).withOpacity(0.45),
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------------- Trending Markets ----------------
          _TrendingMarkets(
            onOpenChart: onOpenChart,
            itemBuilder: (quote) {
              return _buildMarketItem(
                quote.symbol,
                quote.price,
                quote.changePct,
                quote.volume,
                quote.spark,
                () => onOpenChart(quote.symbol),
              );
            },
          ),

          const SizedBox(height: 16),

          // ---------------- Learning Progress + Daily Streak ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListenableBuilder(
              listenable: AiLearningStore.instance,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openLearning(context),
                        child: _buildLearningProgressCard(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openLearning(context),
                        child: _buildDailyStreakCard(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openLearning(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPathScreen(
          onPracticeTrade: () => onTabChange('trade'),
        ),
      ),
    );
  }

  Widget _buildTargetGraphic() {
    return SizedBox(
      width: 160,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Growing gradient bar chart with glow, sits behind/right of target
          Positioned(
            right: -4,
            bottom: 26,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(16),
                const SizedBox(width: 5),
                _bar(30),
                const SizedBox(width: 5),
                _bar(48),
                const SizedBox(width: 5),
                _bar(68),
              ],
            ),
          ),
          // Concentric glowing target rings
          Positioned(
            left: 10,
            top: 28,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.35), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.55), width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.8), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF60A5FA).withOpacity(0.9),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Arrow, drawn precisely with a CustomPainter so it's always a
          // clean straight line piercing the target's center, with the tip
          // poking out past the top-right edge of the rings.
          const Positioned.fill(
            child: CustomPaint(
              painter: _TargetArrowPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA), Color(0xFFBFDBFE)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.5),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton(String label, IconData icon, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinIcon(String symbol) {
    final base = symbol.split('/').first.toUpperCase();

    late final Gradient gradient;
    late final Widget glyph;

    switch (base) {
      case 'BTC':
        gradient = const LinearGradient(
          colors: [Color(0xFFF7931A), Color(0xFFEA580C)],
        );
        glyph = const Text(
          "\u20BF",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        );
        break;
      case 'ETH':
        gradient = const LinearGradient(
          colors: [Color(0xFF3C3C50), Color(0xFF1E1E2E)],
        );
        glyph = Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
        break;
      case 'US100':
        gradient = const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        );
        glyph = const Text(
          "100",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
        );
        break;
      default:
        gradient = const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        );
        glyph = Text(
          base.isNotEmpty ? base[0] : "?",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(child: glyph),
    );
  }

  Widget _buildMarketItem(
      String symbol,
      double price,
      double change,
      String volume,
      List<double> spark,
      VoidCallback onTap,
      ) {
    final ready = price > 0;
    final isPositive = change >= 0;
    final color = !ready
        ? Colors.grey[500]!
        : isPositive
            ? Colors.green[400]!
            : Colors.red[400]!;
    final isIndex = symbol == 'US100';
    final sparkValues = spark.length >= 2
        ? spark
        : (ready ? <double>[price * 0.998, price] : const <double>[]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            _buildCoinIcon(symbol),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(
                    isIndex
                        ? 'Vol: $volume'
                        : volume == '—'
                            ? 'Vol: —'
                            : 'Vol: \$$volume',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              height: 28,
              child: sparkValues.isEmpty
                  ? const SizedBox.shrink()
                  : _Sparkline(values: sparkValues, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ready
                      ? '\$${price.toStringAsFixed(price < 1 ? 4 : 2)}'
                      : '—',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: color,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ready
                          ? '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%'
                          : '—',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningProgressCard() {
    final store = AiLearningStore.instance;
    final progress = store.progress;
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  "Learning Progress",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.menu_book_outlined, color: Color(0xFF8B5CF6), size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 5,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: progress == 0 ? 0.02 : progress,
                        strokeWidth: 5,
                        color: const Color(0xFF22C55E),
                        backgroundColor: Colors.transparent,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      "$pct%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Continue your journey",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${store.completedCount} / ${store.totalLessons} Lessons",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStreakCard() {
    final days = AiLearningStore.instance.streakDays;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  "Daily Streak",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "$days Day${days == 1 ? '' : 's'}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            days == 0 ? "Study or trade to start" : "Keep the streak going",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: days == 0 ? Colors.white54 : const Color(0xFF22C55E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingMarkets extends StatefulWidget {
  final void Function(String symbol) onOpenChart;
  final Widget Function(HomeMarketQuote quote) itemBuilder;

  const _TrendingMarkets({
    required this.onOpenChart,
    required this.itemBuilder,
  });

  @override
  State<_TrendingMarkets> createState() => _TrendingMarketsState();
}

class _TrendingMarketsState extends State<_TrendingMarkets> {
  final _quotes = HomeTrendingQuotes.instance;

  @override
  void initState() {
    super.initState();
    _quotes.attach();
  }

  @override
  void dispose() {
    _quotes.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _quotes,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trending Markets',
                      style: TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: () => widget.onOpenChart('US100'),
                      child: Row(
                        children: [
                          Text('View All',
                              style: TextStyle(color: Colors.blue[400], fontSize: 12)),
                          Icon(Icons.chevron_right, color: Colors.blue[400], size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._quotes.markets.map(widget.itemBuilder),
            ],
          ),
        );
      },
    );
  }
}

/// Small inline sparkline chart used in the Trending Markets list.
class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;

  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(values: values, color: color),
      size: Size.infinite,
    );
  }
}

/// Draws a single clean straight arrow (shaft + triangular head) diagonally
/// across the target graphic, from lower-left toward the upper-right.
class _TargetArrowPainter extends CustomPainter {
  const _TargetArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Anchored relative to the target circle, which sits at
    // left:10, top:28, 84x84 -> center is roughly (52, 70).
    final start = Offset(30, 108);
    final end = Offset(128, 6);

    final angle = atan2(end.dy - start.dy, end.dx - start.dx);

    // Soft glow pass underneath.
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(start, end, glowPaint);

    // Crisp shaft on top.
    final shaftPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, shaftPaint);

    // Arrowhead triangle at the tip, pointing along the shaft's direction.
    const arrowLength = 16.0;
    const arrowSpread = pi / 7;
    final p2 = Offset(
      end.dx - arrowLength * cos(angle - arrowSpread),
      end.dy - arrowLength * sin(angle - arrowSpread),
    );
    final p3 = Offset(
      end.dx - arrowLength * cos(angle + arrowSpread),
      end.dy - arrowLength * sin(angle + arrowSpread),
    );
    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(headPath, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TargetArrowPainter oldDelegate) => false;
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = (values[i] - minV) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.values.length != values.length ||
        !_listEq(oldDelegate.values, values);
  }

  bool _listEq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}