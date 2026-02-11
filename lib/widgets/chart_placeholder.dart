import 'package:flutter/material.dart';

class ChartPlaceholder extends StatefulWidget {
  final String symbol;

  const ChartPlaceholder({super.key, required this.symbol});

  @override
  State<ChartPlaceholder> createState() => _ChartPlaceholderState();
}

class _ChartPlaceholderState extends State<ChartPlaceholder> {
  String activeTimeframe = '15m';
  final timeframes = ['1m', '5m', '15m', '1H', '4H', '1D', '1W'];
  final currentPrice = 42856.32;
  final priceChange = 2.34;

  @override
  Widget build(BuildContext context) {
    final isPositive = priceChange >= 0;

    return Container(
      color: const Color(0xFF0D0D0F),
      child: Column(
        children: [
          // Price Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '\$${currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isPositive ? Colors.green : Colors.red).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive ? Icons.trending_up : Icons.trending_down,
                                    color: isPositive ? Colors.green[400] : Colors.red[400],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? '+' : ''}$priceChange%',
                                    style: TextStyle(
                                      color: isPositive ? Colors.green[400] : Colors.red[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '≈ \$42,856.32 USD',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildIconButton(Icons.layers_outlined),
                        const SizedBox(width: 8),
                        _buildIconButton(Icons.tune),
                        const SizedBox(width: 8),
                        _buildIconButton(Icons.fullscreen),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Timeframe Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: timeframes.map((tf) {
                      final isActive = activeTimeframe == tf;
                      return GestureDetector(
                        onTap: () => setState(() => activeTimeframe = tf),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isActive
                                ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8)]
                                : null,
                          ),
                          child: Text(
                            tf,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Chart Area
          Expanded(
            child: Stack(
              children: [
                // Grid Background
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0F),
                  ),
                ),
                // Placeholder
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.2),
                              const Color(0xFF8B5CF6).withOpacity(0.2),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Icon(Icons.show_chart, color: Colors.blue[400], size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chart Area',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect API to display live chart',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      // Fake candlestick preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(20, (i) {
                          final heights = [40, 55, 45, 60, 50, 70, 65, 80, 75, 60, 70, 55, 65, 75, 85, 70, 80, 90, 85, 75];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 6,
                            height: heights[i].toDouble(),
                            decoration: BoxDecoration(
                              color: i % 3 == 0
                                  ? Colors.red.withOpacity(0.4)
                                  : Colors.green.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('24h High', '\$43,250', Colors.green[400]!),
                _buildStat('24h Low', '\$41,890', Colors.red[400]!),
                _buildStat('24h Vol', '\$2.4B', Colors.white),
                _buildStat('Open Int.', '\$890M', Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.grey[400], size: 18),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}