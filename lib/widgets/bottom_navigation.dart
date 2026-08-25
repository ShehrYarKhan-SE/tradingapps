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
  static const Color coachColor = Color(0xFFA855F7);
  static const Color inactiveColor = Colors.white54;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'id': 'home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'id': 'trade', 'icon': Icons.swap_horiz, 'activeIcon': Icons.swap_horiz, 'label': 'Trade'},
      {'id': 'chart', 'icon': Icons.show_chart, 'activeIcon': Icons.show_chart, 'label': 'Chart'},
      {'id': 'coach', 'icon': Icons.smart_toy_outlined, 'activeIcon': Icons.smart_toy, 'label': 'AI Coach'},
      {'id': 'portfolio', 'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet, 'label': 'Portfolio'},
      {'id': 'profile', 'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xF2141B2E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: navItems.map((item) {
          final id = item['id'] as String;
          final isActive = activeTab == id;
          final isCoach = id == 'coach';
          final color = isActive
              ? (isCoach ? coachColor : activeColor)
              : inactiveColor;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (id == 'profile') {
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
                  Container(
                    decoration: isActive && isCoach
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: coachColor.withValues(alpha: 0.7),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          )
                        : null,
                    child: Icon(
                      isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
