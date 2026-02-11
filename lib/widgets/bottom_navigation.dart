import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const BottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'id': 'home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'id': 'trade', 'icon': Icons.swap_horiz, 'activeIcon': Icons.swap_horiz, 'label': 'Trade'},
      {'id': 'chart', 'icon': Icons.show_chart, 'activeIcon': Icons.show_chart, 'label': 'Chart', 'isMain': true},
      {'id': 'portfolio', 'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet, 'label': 'Portfolio'},
      {'id': 'settings', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'label': 'Settings'},
    ];

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 24, left: 8, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F).withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) {
          final isActive = activeTab == item['id'];
          final isMain = item['isMain'] == true;

          if (isMain) {
            return _buildMainButton(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              isActive: isActive,
              onTap: () => onTabChange(item['id'] as String),
            );
          }

          return _buildNavItem(
            icon: (isActive ? item['activeIcon'] : item['icon']) as IconData,
            label: item['label'] as String,
            isActive: isActive,
            onTap: () => onTabChange(item['id'] as String),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(isActive ? 0.6 : 0.3),
                    blurRadius: isActive ? 30 : 20,
                    spreadRadius: isActive ? 2 : 0,
                  ),
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(child: Icon(icon, color: Colors.white, size: 28)),
                  // Shine effect
                  Positioned(
                    top: 4,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFA855F7) : Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF3B82F6) : Colors.grey[500],
                  size: 22,
                ),
                if (isActive)
                  Positioned(
                    top: 0,
                    left: 4,
                    right: 4,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (isActive)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF3B82F6) : Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}