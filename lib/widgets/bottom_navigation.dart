import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';

class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const BottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  static const Color activeColor = Color(0xFF3B82F6);
  static const Color inactiveColor = Colors.white54;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'id': 'home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'id': 'trade', 'icon': Icons.swap_horiz, 'activeIcon': Icons.swap_horiz, 'label': 'Trade'},
      {'id': 'chart', 'icon': Icons.show_chart, 'activeIcon': Icons.show_chart, 'label': 'Chart'},
      {'id': 'portfolio', 'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet, 'label': 'Portfolio'},
      {'id': 'profile', 'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navItems.map((item) {
          final id = item['id'] as String;
          final isActive = activeTab == id;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (id == 'profile') {
                // Profile is a full standalone screen, so push it instead
                // of swapping the tab body like the other tabs.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else {
                onTabChange(id);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                  color: isActive ? activeColor : inactiveColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isActive ? activeColor : inactiveColor,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}