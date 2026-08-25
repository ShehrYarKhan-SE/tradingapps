import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tradingapps/theme_controller.dart';
import '../screens/profile_screen.dart';
import '../screens/Notification_Screen.dart';
import '../service/user_account_store.dart';
import '../service/ai_learning_store.dart';

class MobileSettings extends StatelessWidget {
  const MobileSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Settings",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ---------------- Profile Card ----------------
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                FirebaseAuth.instance.currentUser?.displayName ??
                                    "User",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.purple[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? "",
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              "Member since May 2024",
                              style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
          ),

          // ---------------- Account ----------------
          _buildSettingsGroup(
            context,
            'Account',
            [
              {
                'icon': Icons.person_outline,
                'label': 'Edit Profile',
                'subtitle': 'Update your name and profile picture',
                'color': const Color(0xFF8B5CF6),
                'onTap': () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              },
              {
                'icon': Icons.email_outlined,
                'label': 'Email Address',
                'subtitle': FirebaseAuth.instance.currentUser?.email ?? "",
                'color': const Color(0xFF3B82F6),
                'onTap': () {
                  // TODO: navigate to Email settings
                },
              },
              {
                'icon': Icons.lock_outline,
                'label': 'Change Password',
                'subtitle': 'Update your password',
                'color': const Color(0xFF22C55E),
                'onTap': () {
                  _showChangePasswordDialog(context);
                },
              },
              {
                'icon': Icons.badge_outlined,
                'label': 'Personal Information',
                'subtitle': 'Manage your personal details',
                'color': const Color(0xFFF59E0B),
                'onTap': () {
                  // TODO: navigate to Personal Information screen
                },
              },
            ],
          ),

          // ---------------- Preferences ----------------
          _buildSettingsGroup(
            context,
            'Preferences',
            [
              {
                'icon': Icons.currency_bitcoin,
                'label': 'Default Market',
                'subtitle': 'BTC/USDT',
                'color': const Color(0xFFF59E0B),
                'onTap': () {
                  // TODO: open Default Market picker
                },
              },
              {
                'icon': Icons.swap_horiz,
                'label': 'Default Order Type',
                'subtitle': 'Market',
                'color': const Color(0xFF3B82F6),
                'onTap': () {
                  // TODO: open Default Order Type picker
                },
              },
              {
                'icon': Icons.attach_money,
                'label': 'Default Currency',
                'subtitle': 'USDT',
                'color': const Color(0xFF22C55E),
                'onTap': () {
                  // TODO: open Default Currency picker
                },
              },
              {
                'icon': Icons.notifications_none,
                'label': 'Price Alerts',
                'subtitle': 'Manage your price alerts',
                'color': const Color(0xFF8B5CF6),
                'onTap': () {
                  AiLearningStore.instance.bind();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              },
              {
                'icon': Icons.dark_mode_outlined,
                'label': 'Theme',
                'subtitle': 'Change app appearance',
                'color': const Color(0xFF8B5CF6),
                'hasSwitch': true,
                'isDarkMode': true,
              },
            ],
          ),

          // ---------------- Security ----------------
          _buildSettingsGroup(
            context,
            'Security',
            [
              {
                'icon': Icons.shield_outlined,
                'label': 'Two-Factor Authentication',
                'subtitle': 'Add extra security to your account',
                'color': const Color(0xFF22C55E),
                'onTap': () {
                  // TODO: navigate to 2FA screen
                },
              },
              {
                'icon': Icons.security,
                'label': 'Login Activity',
                'subtitle': 'Review your recent login activity',
                'color': const Color(0xFF3B82F6),
                'onTap': () {
                  // TODO: navigate to Login Activity screen
                },
              },
              {
                'icon': Icons.devices_other,
                'label': 'Devices',
                'subtitle': 'Manage your connected devices',
                'color': const Color(0xFF8B5CF6),
                'onTap': () {
                  // TODO: navigate to Devices screen
                },
              },
            ],
          ),

          // ---------------- Support ----------------
          _buildSettingsGroup(
            context,
            'Support',
            [
              {
                'icon': Icons.help_outline,
                'label': 'Help Center',
                'subtitle': 'FAQs and support articles',
                'color': const Color(0xFF22C55E),
                'onTap': () {
                  // TODO: navigate to Help Center screen
                },
              },
              {
                'icon': Icons.headset_mic_outlined,
                'label': 'Contact Us',
                'subtitle': 'Get in touch with our support team',
                'color': const Color(0xFF3B82F6),
                'onTap': () {
                  // TODO: navigate to Contact Us screen
                },
              },
              {
                'icon': Icons.info_outline,
                'label': 'About Us',
                'subtitle': 'Learn more about Virtual Trading AI',
                'color': const Color(0xFF8B5CF6),
                'onTap': () {
                  // TODO: navigate to About Us screen
                },
              },
            ],
          ),

          // NOTE: Bottom "Log Out" button intentionally removed from Settings.
          // Logout is now only available from the Mobile Header menu and the
          // Profile screen.
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    TextEditingController currentPassword = TextEditingController();
    TextEditingController newPassword = TextEditingController();
    TextEditingController confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassword,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Current Password"),
            ),
            TextField(
              controller: newPassword,
              obscureText: true,
              decoration: const InputDecoration(hintText: "New Password"),
            ),
            TextField(
              controller: confirmPassword,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Confirm New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPassword.text != confirmPassword.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match")),
                );
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser!;
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPassword.text,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword.text);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password Updated")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
      BuildContext context,
      String title,
      List<Map<String, dynamic>> items,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final bool isDarkModeItem = item['isDarkMode'] == true;
                final Color iconColor =
                    (item['color'] as Color?) ?? Colors.grey;
                final VoidCallback? onTap =
                item['onTap'] as VoidCallback?;

                return InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: i < items.length - 1
                          ? Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withOpacity(0.1),
                        ),
                      )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'] as String,
                                style:
                                const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                item['subtitle'] as String,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDarkModeItem)
                          ValueListenableBuilder<bool>(
                            valueListenable: isDarkMode,
                            builder: (context, darkMode, child) {
                              return Switch(
                                value: darkMode,
                                onChanged: (value) {
                                  isDarkMode.value = value;
                                  UserAccountStore.instance.darkMode = value;
                                  UserAccountStore.instance.saveAll();
                                },
                                activeColor: const Color(0xFF8B5CF6),
                              );
                            },
                          )
                        else if (item['hasSwitch'] == true)
                          Switch(
                            value: true,
                            onChanged: (_) {},
                            activeColor: const Color(0xFF8B5CF6),
                          )
                        else
                          Icon(Icons.chevron_right,
                              color: Colors.grey[600], size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}