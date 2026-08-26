import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/ai_learning_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/Notification_Screen.dart';
import '../screens/menu_screens.dart';
import '../screens/profile_screen.dart';
import 'mobile_settings.dart';
import '../theme_controller.dart';

class MobileHeader extends StatefulWidget {
  final String mode;
  final Function(String) onModeChange;
  final String symbol;
  final VoidCallback? onSymbolTap;

  const MobileHeader({
    super.key,
    required this.mode,
    required this.onModeChange,
    required this.symbol,
    this.onSymbolTap,
  });

  @override
  State<MobileHeader> createState() => _MobileHeaderState();
}

class _MobileHeaderState extends State<MobileHeader> {
  bool isMenuOpen = false;

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMenuSheet(),
    );
  }

  Widget _buildMenuSheet() {
    final menuItems = [
      {
        'icon': Icons.person,
        'label': 'Profile',
        'subtitle': 'View your profile',
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      },
      {
        'icon': Icons.shield,
        'label': 'Security',
        'subtitle': '2FA & Password',
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityScreen()),
          );
        },
      },
      {
        'icon': Icons.account_balance_wallet,
        'label': 'Wallet',
        'subtitle': 'Manage funds',
        'color': Colors.purple,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          );
        },
      },
      {
        'icon': Icons.card_giftcard,
        'label': 'Rewards',
        'subtitle': 'Claim bonuses',
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RewardsScreen()),
          );
        },
      },
      {
        'icon': Icons.star,
        'label': 'VIP Status',
        'subtitle': 'Pro Member',
        'color': Colors.yellow,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VipStatusScreen()),
          );
        },
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'subtitle': 'App preferences',
        'color': Colors.grey,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                final colors = AppColors.of(context);
                return Scaffold(
                  backgroundColor: colors.scaffold,
                  appBar: AppBar(
                    backgroundColor: colors.header,
                    elevation: 0,
                    title: Text("Settings", style: TextStyle(color: colors.text)),
                    iconTheme: IconThemeData(color: colors.text),
                  ),
                  body: const MobileSettings(showTitle: false),
                );
              },
            ),
          );
        },
      },
      {
        'icon': Icons.help,
        'label': 'Help Center',
        'subtitle': 'Get support',
        'color': Colors.cyan,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
          );
        },
      },
    ];

    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.sheet,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Row(
              children: [
                _buildShinyAvatar(48),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ?? "User",
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? "",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.2),
                            Colors.pink.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'PRO MEMBER',
                        style: TextStyle(
                          color: Color(0xFFA855F7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Menu Items
          ...menuItems.map((item) => _buildMenuItem(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            subtitle: item['subtitle'] as String,
            color: item['color'] as Color,
            onTap: item['onTap'] as VoidCallback,
          )),
          // Logout
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.border),
              ),
            ),
            child: _buildMenuItem(
              icon: Icons.logout,
              label: 'Log Out',
              subtitle: 'Sign out of your account',
              color: Colors.red,
              isLogout: true,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);

          if (isLogout) {
            bool? confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await AuthService.logout();

              if (!context.mounted) return;

              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } else {
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isLogout
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFF87171),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
              : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.of(context).text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShinyAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1A1A1F),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.person,
                color: Colors.grey[400],
                size: size * 0.5,
              ),
            ),
            // Shine effect
            Positioned(
              top: 2,
              left: size * 0.25,
              child: Container(
                width: size * 0.5,
                height: size * 0.3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShinyButton({
    required Widget child,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = const Color(0xFF8B5CF6),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isActive
              ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 20)]
              : null,
        ),
        child: Stack(
          children: [
            child,
            // Shine overlay
            Positioned(
              top: 0,
              left: 5,
              right: 5,
              child: Container(
                height: 10,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.header,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showMenu,
            child: Icon(Icons.menu, color: colors.text, size: 22),
          ),

          const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 6),
              Text(
                "Virtual Trading AI",
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const Spacer(),

          Material(
            color: Colors.transparent,
            child: ListenableBuilder(
              listenable: AiLearningStore.instance,
              builder: (context, _) {
                final notificationCount = AiLearningStore.instance.notices.length;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    AiLearningStore.instance.bind();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.notifications_outlined, color: colors.muted, size: 22),
                        if (notificationCount > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                notificationCount > 9 ? '9+' : '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}