import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tradingapps/theme_controller.dart';
import '../screens/profile_screen.dart';
import '../screens/Notification_Screen.dart';
import '../screens/menu_screens.dart';
import '../service/user_account_store.dart';
import '../service/ai_learning_store.dart';
import '../service/chart_workspace.dart';

class MobileSettings extends StatefulWidget {
  const MobileSettings({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  State<MobileSettings> createState() => _MobileSettingsState();
}

class _MobileSettingsState extends State<MobileSettings> {
  UserAccountStore get _store => UserAccountStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  String get _memberSince {
    final created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (created == null) return 'Member';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return 'Member since ${months[created.month - 1]} ${created.year}';
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required Future<void> Function(String) onSave,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.of(context).sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetColors = AppColors.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    color: sheetColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...options.map((o) {
                final selected = o == current;
                return ListTile(
                  title: Text(o, style: TextStyle(color: sheetColors.text)),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF22C55E))
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || picked == current) return;
    await onSave(picked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title set to $picked')),
      );
    }
  }

  Future<void> _showEmailSheet() async {
    final user = FirebaseAuth.instance.currentUser;
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Email address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDeco('New email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDeco('Current password'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = emailCtrl.text.trim();
                    if (user == null || !email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid email')),
                      );
                      return;
                    }
                    try {
                      final cred = EmailAuthProvider.credential(
                        email: user.email ?? email,
                        password: passCtrl.text,
                      );
                      await user.reauthenticateWithCredential(cred);
                      await user.verifyBeforeUpdateEmail(email);
                      _store.email = email;
                      await _store.saveAll();
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Check your inbox to confirm the new email',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_authError(e))),
                      );
                    }
                  },
                  child: const Text('Save email'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPersonalInfo() async {
    final nameCtrl = TextEditingController(
      text: _store.displayName.isNotEmpty
          ? _store.displayName
          : (FirebaseAuth.instance.currentUser?.displayName ?? ''),
    );
    final phoneCtrl = TextEditingController(text: _store.phone);
    var country = _store.country;
    var timezone = _store.timezone;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDeco('Full name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDeco('Phone number'),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Country',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    subtitle: Text(
                      country,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.public, color: Colors.white54),
                    onTap: () {
                      showCountryPicker(
                        context: ctx,
                        showPhoneCode: false,
                        onSelect: (c) {
                          setSheet(() {
                            country = c.name;
                            timezone =
                                '(GMT) ${c.countryCode} local time';
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        _store.displayName = name;
                        _store.username = name.isEmpty
                            ? _store.username
                            : name.toLowerCase().replaceAll(' ', '_');
                        _store.phone = phoneCtrl.text.trim();
                        _store.country = country;
                        _store.timezone = timezone;
                        try {
                          await FirebaseAuth.instance.currentUser
                              ?.updateDisplayName(name);
                        } catch (_) {}
                        await _store.saveAll();
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile saved')),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _fieldDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _authError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Current password is incorrect';
        case 'requires-recent-login':
          return 'Sign in again, then retry';
        case 'email-already-in-use':
          return 'That email is already in use';
        case 'weak-password':
          return 'Use at least 6 characters';
        default:
          return e.message ?? 'Could not update account';
      }
    }
    return 'Could not update account';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = _store.displayName.isNotEmpty
        ? _store.displayName
        : (user?.displayName ?? 'User');
    final email = user?.email ?? _store.email;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Settings",
                style: TextStyle(
                  color: AppColors.of(context).text,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _open(const ProfileScreen()),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.of(context).border,
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
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              _memberSince,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
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
          _buildSettingsGroup(
            context,
            'Account',
            [
              {
                'icon': Icons.person_outline,
                'label': 'Edit Profile',
                'subtitle': 'Update your name and profile picture',
                'color': const Color(0xFF8B5CF6),
                'onTap': () => _open(const ProfileScreen()),
              },
              {
                'icon': Icons.email_outlined,
                'label': 'Email Address',
                'subtitle': email.isEmpty ? 'Add an email' : email,
                'color': const Color(0xFF3B82F6),
                'onTap': _showEmailSheet,
              },
              {
                'icon': Icons.lock_outline,
                'label': 'Change Password',
                'subtitle': 'Update your password',
                'color': const Color(0xFF22C55E),
                'onTap': () => _showChangePasswordDialog(context),
              },
              {
                'icon': Icons.badge_outlined,
                'label': 'Personal Information',
                'subtitle': _store.country,
                'color': const Color(0xFFF59E0B),
                'onTap': _showPersonalInfo,
              },
            ],
          ),
          _buildSettingsGroup(
            context,
            'Preferences',
            [
              {
                'icon': Icons.currency_bitcoin,
                'label': 'Default Market',
                'subtitle': _store.defaultMarket,
                'color': const Color(0xFFF59E0B),
                'onTap': () => _pickOption(
                  title: 'Default market',
                  options: ChartWorkspace.displaySymbols,
                  current: _store.defaultMarket,
                  onSave: (v) async {
                    _store.defaultMarket = v;
                    _store.chartSymbol = v;
                    await _store.saveAll();
                  },
                ),
              },
              {
                'icon': Icons.swap_horiz,
                'label': 'Default Order Type',
                'subtitle': _store.defaultOrderType,
                'color': const Color(0xFF3B82F6),
                'onTap': () => _pickOption(
                  title: 'Default order type',
                  options: const ['Market', 'Limit', 'Stop'],
                  current: _store.defaultOrderType,
                  onSave: (v) async {
                    _store.defaultOrderType = v;
                    await _store.saveAll();
                  },
                ),
              },
              {
                'icon': Icons.attach_money,
                'label': 'Default Currency',
                'subtitle': _store.defaultCurrency,
                'color': const Color(0xFF22C55E),
                'onTap': () => _pickOption(
                  title: 'Default currency',
                  options: const ['USDT', 'USD', 'EUR', 'PKR'],
                  current: _store.defaultCurrency,
                  onSave: (v) async {
                    _store.defaultCurrency = v;
                    await _store.saveAll();
                  },
                ),
              },
              {
                'icon': Icons.notifications_none,
                'label': 'Price Alerts',
                'subtitle': 'Manage your price alerts',
                'color': const Color(0xFF8B5CF6),
                'onTap': () {
                  AiLearningStore.instance.bind();
                  _open(const NotificationsScreen());
                },
              },
              {
                'icon': isDarkMode.value
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                'label': 'Theme',
                'subtitle': isDarkMode.value ? 'Dark mode' : 'Light mode',
                'color': const Color(0xFF8B5CF6),
                'hasSwitch': true,
                'isDarkMode': true,
              },
            ],
          ),
          _buildSettingsGroup(
            context,
            'Security',
            [
              {
                'icon': Icons.shield_outlined,
                'label': 'Two-Factor Authentication',
                'subtitle': _store.twoFAEnabled ? 'Enabled' : 'Add extra security',
                'color': const Color(0xFF22C55E),
                'onTap': () => _open(const SecurityScreen()),
              },
              {
                'icon': Icons.security,
                'label': 'Login Activity',
                'subtitle': _store.loginHistory.isEmpty
                    ? 'No recent logins'
                    : '${_store.loginHistory.length} recent sign-ins',
                'color': const Color(0xFF3B82F6),
                'onTap': () => _open(const LoginActivityScreen()),
              },
              {
                'icon': Icons.devices_other,
                'label': 'Devices',
                'subtitle': '${_store.devices.length} linked device${_store.devices.length == 1 ? '' : 's'}',
                'color': const Color(0xFF8B5CF6),
                'onTap': () => _open(const DevicesScreen()),
              },
            ],
          ),
          _buildSettingsGroup(
            context,
            'Support',
            [
              {
                'icon': Icons.help_outline,
                'label': 'Help Center',
                'subtitle': 'FAQs and support articles',
                'color': const Color(0xFF22C55E),
                'onTap': () => _open(const HelpCenterScreen()),
              },
              {
                'icon': Icons.headset_mic_outlined,
                'label': 'Contact Us',
                'subtitle': 'Get in touch with our support team',
                'color': const Color(0xFF3B82F6),
                'onTap': () => _open(const ContactUsScreen()),
              },
              {
                'icon': Icons.info_outline,
                'label': 'About Us',
                'subtitle': 'Learn more about Virtual Trading AI',
                'color': const Color(0xFF8B5CF6),
                'onTap': () => _open(const AboutUsScreen()),
              },
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    await showDialog<void>(
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
              if (newPassword.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password must be at least 6 characters"),
                  ),
                );
                return;
              }
              if (newPassword.text != confirmPassword.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match")),
                );
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  throw FirebaseAuthException(code: 'requires-recent-login');
                }
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPassword.text,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword.text);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password updated")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_authError(e))),
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
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.of(context).border,
              ),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final bool isDarkModeItem = item['isDarkMode'] == true;
                final Color iconColor = (item['color'] as Color?) ?? Colors.grey;
                final VoidCallback? onTap = item['onTap'] as VoidCallback?;

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
                                    .withValues(alpha: 0.1),
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
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
                                style: const TextStyle(fontWeight: FontWeight.w500),
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
                                  AppColors.setUiOverlay(value);
                                  UserAccountStore.instance.darkMode = value;
                                  UserAccountStore.instance.saveAll();
                                },
                                activeColor: const Color(0xFF8B5CF6),
                              );
                            },
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
