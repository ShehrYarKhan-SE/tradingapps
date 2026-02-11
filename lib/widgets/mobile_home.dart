import 'package:flutter/material.dart';

class MobileHome extends StatelessWidget {
  final Function(String) onTabChange;

  const MobileHome({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final trendingPairs = [
      {'symbol': 'BTC/USDT', 'price': 42856.32, 'change': 2.34, 'volume': '2.4B'},
      {'symbol': 'ETH/USDT', 'price': 2284.56, 'change': -1.23, 'volume': '1.2B'},
      {'symbol': 'SOL/USDT', 'price': 98.45, 'change': 5.67, 'volume': '890M'},
      {'symbol': 'DOGE/USDT', 'price': 0.0823, 'change': 8.45, 'volume': '456M'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Welcome Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildCardButton('Demo Mode', Icons.bolt, false),
                        const SizedBox(width: 8),
                        _buildCardButton('AI Coach', Icons.psychology, true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Win Rate', '68%', Colors.green, Icons.track_changes),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Total P&L', '+\$2,450', Colors.blue, Icons.emoji_events),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Trending Markets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trending Markets',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text('View All', style: TextStyle(color: Colors.blue[400], fontSize: 12)),
                    Icon(Icons.chevron_right, color: Colors.blue[400], size: 16),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ...trendingPairs.map((pair) => _buildMarketItem(
            pair['symbol'] as String,
            pair['price'] as double,
            pair['change'] as double,
            pair['volume'] as String,
            onTabChange,
          )),
        ],
      ),
    );
  }

  Widget _buildCardButton(String label, IconData icon, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isPrimary ? const Color(0xFF8B5CF6) : Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? const Color(0xFF8B5CF6) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketItem(String symbol, double price, double change, String volume, Function(String) onTap) {
    final isPositive = change >= 0;
    return GestureDetector(
      onTap: () => onTap('chart'),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  symbol[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('Vol: \$$volume', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${price.toStringAsFixed(price < 1 ? 4 : 2)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green[400] : Colors.red[400],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? Colors.green[400] : Colors.red[400],
                        fontSize: 12,
                      ),
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
}