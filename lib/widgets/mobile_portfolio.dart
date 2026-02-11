import 'package:flutter/material.dart';

class MobilePortfolio extends StatelessWidget {
  const MobilePortfolio({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Balance Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                  const Color(0xFFEC4899).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text('Total Balance', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      ],
                    ),
                    Icon(Icons.visibility_outlined, color: Colors.grey[400], size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '\$100000',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, color: Colors.green[400], size: 14),
                          const SizedBox(width: 4),
                          Text('+2.36%', style: TextStyle(color: Colors.green[400], fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('+\$1,245.67', style: TextStyle(color: Colors.green[400], fontSize: 14)),
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
                _buildQuickStat('Today P&L', '+\$456.78', Colors.green[400]!),
                const SizedBox(width: 12),
                _buildQuickStat('Win Rate', '68%', Colors.white),
                const SizedBox(width: 12),
                _buildQuickStat('Total Trades', '156', Colors.white),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Holdings Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Holdings', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('View All', style: TextStyle(color: Colors.blue[400], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Holdings List
          _buildHoldingItem('BTC', 'Bitcoin', '₿', 0.5234, 22456.78, 2.34),
          _buildHoldingItem('ETH', 'Ethereum', 'Ξ', 5.234, 11967.23, -1.23),
          _buildHoldingItem('SOL', 'Solana', '◎', 45.67, 4498.12, 5.67),
          _buildHoldingItem('USDT', 'Tether', '₮', 15000, 15000.00, 0),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingItem(String symbol, String name, String icon, double amount, double value, double change) {
    final isPositive = change >= 0;
    return Container(
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
              gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('$amount $symbol', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(color: change == 0 ? Colors.grey : (isPositive ? Colors.green[400] : Colors.red[400]), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}