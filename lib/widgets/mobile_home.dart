import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/profile_screen.dart';
import '../screens/smc_library_screen.dart';
import '../screens/learning_path_screen.dart';
import '../service/ai_learning_store.dart';
import '../service/home_trending_quotes.dart';
import '../service/user_account_store.dart';
import '../theme_controller.dart';

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
    final colors = AppColors.of(context);
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
                            border: Border.all(color: colors.header, width: 2),
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
                        style: TextStyle(
                          color: colors.text,
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFD946EF).withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/branding/home_welcome_bg.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.35, 0),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xF2080B22),
                            Color(0x99080B22),
                            Color(0x33080B22),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, Trader!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ready to practice?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trade with virtual money,\nlearn with real confidence.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _neonButton(
                                label: 'Demo Mode',
                                icon: Icons.bolt,
                                colors: const [Color(0xFF06B6D4), Color(0xFF2563EB)],
                                glow: const Color(0xFF22D3EE),
                                onTap: () => onTabChange('trade'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _neonButton(
                                label: 'AI Coach',
                                icon: Icons.smart_toy_outlined,
                                colors: const [Color(0xFFD946EF), Color(0xFF7C3AED)],
                                glow: const Color(0xFFE879F9),
                                onTap: () => onTabChange('coach'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                colors,
              );
            },
          ),

          const SizedBox(height: 16),

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SmcLibraryScreen(),
                            ),
                          );
                        },
                        child: _buildLearningProgressCard(colors),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LearningPathScreen(
                                onPracticeTrade: () => onTabChange('trade'),
                              ),
                            ),
                          );
                        },
                        child: _buildDailyStreakCard(colors),
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

  Widget _neonButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required Color glow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.55),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
      AppColors colors,
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
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
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
                      style: TextStyle(color: colors.text, fontWeight: FontWeight.w600)),
                  Text(
                    isIndex
                        ? 'Vol: $volume'
                        : volume == '—'
                            ? 'Vol: —'
                            : 'Vol: \$$volume',
                    style: TextStyle(color: colors.muted, fontSize: 12),
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
                  style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
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

  Widget _buildLearningProgressCard(AppColors colors) {
    final store = AiLearningStore.instance;
    final progress = store.progress;
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Learning Progress",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.menu_book_outlined, color: Color(0xFF8B5CF6), size: 16),
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
                        color: colors.border,
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
                      style: TextStyle(
                        color: colors.text,
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
                    Text(
                      "Continue your journey",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 11),
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

  Widget _buildDailyStreakCard(AppColors colors) {
    final days = AiLearningStore.instance.streakDays;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Daily Streak",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 16),
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
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.muted, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            days == 0 ? "Study or trade to start" : "Keep the streak going",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: days == 0 ? colors.muted : const Color(0xFF22C55E),
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
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: _quotes,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Markets',
                      style: TextStyle(
                          color: colors.text, fontSize: 15, fontWeight: FontWeight.w600),
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