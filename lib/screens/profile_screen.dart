import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final User? user = FirebaseAuth.instance.currentUser;

  // ---- Extra profile fields shown in the design (not part of FirebaseAuth,
  // so we keep them as local state you can later load/save from Firestore) ----
  String _username = "shehryar_khan";
  String _country = "Pakistan";
  String _timezone = "(GMT+5) Pakistan Time";
  String _defaultMarket = "BTC/USDT";
  String _defaultOrderType = "Market";
  String _defaultCurrency = "USDT";
  final double _demoBalance = 100000.00;
  final String _plan = "Demo Pro Plan";

  // ---------------- Country code (ISO2) -> Timezone label ----------------
  // Extend this map any time you need more countries. Fallback is handled
  // in _getTimezoneForCountry().
  static const Map<String, String> _countryTimezones = {
    "PK": "(GMT+5:00) Pakistan Standard Time",
    "IN": "(GMT+5:30) India Standard Time",
    "BD": "(GMT+6:00) Bangladesh Standard Time",
    "AF": "(GMT+4:30) Afghanistan Time",
    "AE": "(GMT+4:00) Gulf Standard Time",
    "SA": "(GMT+3:00) Arabia Standard Time",
    "QA": "(GMT+3:00) Arabia Standard Time",
    "KW": "(GMT+3:00) Arabia Standard Time",
    "TR": "(GMT+3:00) Turkey Time",
    "EG": "(GMT+2:00) Eastern European Time",
    "ZA": "(GMT+2:00) South Africa Standard Time",
    "GB": "(GMT+0:00) Greenwich Mean Time",
    "IE": "(GMT+0:00) Greenwich Mean Time",
    "PT": "(GMT+0:00) Western European Time",
    "FR": "(GMT+1:00) Central European Time",
    "DE": "(GMT+1:00) Central European Time",
    "IT": "(GMT+1:00) Central European Time",
    "ES": "(GMT+1:00) Central European Time",
    "NL": "(GMT+1:00) Central European Time",
    "CH": "(GMT+1:00) Central European Time",
    "PL": "(GMT+1:00) Central European Time",
    "RU": "(GMT+3:00) Moscow Standard Time",
    "CN": "(GMT+8:00) China Standard Time",
    "HK": "(GMT+8:00) Hong Kong Time",
    "SG": "(GMT+8:00) Singapore Time",
    "MY": "(GMT+8:00) Malaysia Time",
    "PH": "(GMT+8:00) Philippine Time",
    "JP": "(GMT+9:00) Japan Standard Time",
    "KR": "(GMT+9:00) Korea Standard Time",
    "ID": "(GMT+7:00) Western Indonesia Time",
    "TH": "(GMT+7:00) Indochina Time",
    "VN": "(GMT+7:00) Indochina Time",
    "AU": "(GMT+10:00) Australian Eastern Time",
    "NZ": "(GMT+12:00) New Zealand Time",
    "US": "(GMT-5:00) Eastern Time",
    "CA": "(GMT-5:00) Eastern Time",
    "MX": "(GMT-6:00) Central Time",
    "BR": "(GMT-3:00) BrasÃ­lia Time",
    "AR": "(GMT-3:00) Argentina Time",
    "NG": "(GMT+1:00) West Africa Time",
    "KE": "(GMT+3:00) East Africa Time",
    "IR": "(GMT+3:30) Iran Standard Time",
    "IQ": "(GMT+3:00) Arabia Standard Time",
    "IL": "(GMT+2:00) Israel Standard Time",
    "UA": "(GMT+2:00) Eastern European Time",
    "SE": "(GMT+1:00) Central European Time",
    "NO": "(GMT+1:00) Central European Time",
    "DK": "(GMT+1:00) Central European Time",
    "FI": "(GMT+2:00) Eastern European Time",
    "GR": "(GMT+2:00) Eastern European Time",
  };

  String _getTimezoneForCountry(String isoCode) {
    return _countryTimezones[isoCode.toUpperCase()] ??
        "Timezone not set â€” please select manually";
  }

  // ---------------- Colors (dark theme like the screenshot) ----------------
  static const Color bgColor = Color(0xFF0B1120);
  static const Color cardColor = Color(0xFF141B2E);
  static const Color borderColor = Color(0xFF232B41);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _showEditDialog() async {
    TextEditingController controller = TextEditingController(
      text: user?.displayName ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text("Edit Username", style: TextStyle(color: textPrimary)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: textPrimary),
            decoration: const InputDecoration(
              hintText: "Enter new username",
              hintStyle: TextStyle(color: textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await user?.updateDisplayName(controller.text);
                await user?.reload();
                setState(() {});
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendForgotPasswordEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reset link sent to $email")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: textSecondary, fontSize: 13),
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 18,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: textSecondary,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Future<void> _showPasswordDialog() async {
    TextEditingController currentPassword = TextEditingController();
    TextEditingController newPassword = TextEditingController();
    TextEditingController confirmPassword = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          title: const Text(
            "Change Password",
            style: TextStyle(color: textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(
                  controller: currentPassword,
                  hint: "Current Password",
                  obscure: obscureCurrent,
                  onToggle: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                ),
                const SizedBox(height: 10),
                _passwordField(
                  controller: newPassword,
                  hint: "New Password",
                  obscure: obscureNew,
                  onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 10),
                _passwordField(
                  controller: confirmPassword,
                  hint: "Confirm New Password",
                  obscure: obscureConfirm,
                  onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _sendForgotPasswordEmail,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: accentBlue, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (newPassword.text != confirmPassword.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Passwords do not match")),
                          );
                          return;
                        }
                        try {
                          User currentUser = FirebaseAuth.instance.currentUser!;
                          AuthCredential credential = EmailAuthProvider.credential(
                            email: currentUser.email!,
                            password: currentPassword.text,
                          );
                          await currentUser.reauthenticateWithCredential(credential);
                          await currentUser.updatePassword(newPassword.text);
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
                      child: const Text("Save", style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text("Logout", style: TextStyle(color: textPrimary)),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Go to Login screen and remove all previous routes from the stack.
        // Replace `LoginScreen()` below with your actual login widget.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text("Delete Account", style: TextStyle(color: textPrimary)),
        content: const Text(
          "Are you sure? This action cannot be undone.",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirebaseAuth.instance.currentUser?.delete();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  // Generic single-field edit dialog for the simple info rows
  Future<void> _editSimpleField({
    required String title,
    required String currentValue,
    required Function(String) onSaved,
  }) async {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(title, style: const TextStyle(color: textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              onSaved(controller.text);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------- Country picker with flags + auto timezone ----------------
  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: cardColor,
        textStyle: const TextStyle(color: textPrimary),
        searchTextStyle: const TextStyle(color: textPrimary),
        inputDecoration: InputDecoration(
          hintText: "Search country",
          hintStyle: const TextStyle(color: textSecondary),
          prefixIcon: const Icon(Icons.search, color: textSecondary),
          filled: true,
          fillColor: bgColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          // country.name = full country name, country.flagEmoji = flag emoji
          _country = "${country.flagEmoji}  ${country.name}";
          _timezone = _getTimezoneForCountry(country.countryCode);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bolt, color: accentBlue),
            SizedBox(width: 6),
            Text(
              "TradeMaster AI",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.notifications_none, color: textPrimary, size: 26),
              ),
              Positioned(
                right: 12,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "3",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profile",
              style: TextStyle(
                color: textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ---------------- Profile Card ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [accentBlue, accentPurple],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: bgColor,
                          backgroundImage:
                          _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person, size: 40, color: textPrimary)
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: accentBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
                                currentUser?.displayName ?? "No Name",
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildBadge("PRO", accentPurple),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: accentOrange, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.email ?? "",
                          style: const TextStyle(color: textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.calendar_today, size: 12, color: textSecondary),
                            SizedBox(width: 4),
                            Text(
                              "Member since May 2024",
                              style: TextStyle(color: textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- Account Information ----------------
            _sectionTitle("Account Information"),
            _sectionCard([
              _infoTile(
                icon: Icons.person_outline,
                iconBg: accentPurple,
                title: "Full Name",
                value: currentUser?.displayName ?? "-",
                onTap: _showEditDialog,
              ),
              _infoTile(
                icon: Icons.email_outlined,
                iconBg: accentBlue,
                title: "Email Address",
                value: currentUser?.email ?? "-",
                onTap: () {},
              ),
              _infoTile(
                icon: Icons.alternate_email,
                iconBg: accentGreen,
                title: "Username",
                value: _username,
                onTap: () => _editSimpleField(
                  title: "Username",
                  currentValue: _username,
                  onSaved: (v) => _username = v,
                ),
              ),
              _infoTile(
                icon: Icons.public,
                iconBg: accentOrange,
                title: "Country",
                value: _country,
                // Now opens the full world country list with flags instead
                // of a plain text field. Selecting a country also updates
                // the Timezone row below automatically.
                onTap: _pickCountry,
              ),
              _infoTile(
                icon: Icons.access_time,
                iconBg: accentPurple,
                title: "Timezone",
                value: _timezone,
                // Timezone is now derived from the selected country, so we
                // just show it (tap re-opens the country picker to change it).
                onTap: _pickCountry,
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // ---------------- Trading Preferences ----------------
            _sectionTitle("Trading Preferences"),
            _sectionCard([
              _infoTile(
                icon: Icons.currency_bitcoin,
                iconBg: accentOrange,
                title: "Default Market",
                value: _defaultMarket,
                onTap: () => _editSimpleField(
                  title: "Default Market",
                  currentValue: _defaultMarket,
                  onSaved: (v) => _defaultMarket = v,
                ),
              ),
              _infoTile(
                icon: Icons.swap_horiz,
                iconBg: accentBlue,
                title: "Default Order Type",
                value: _defaultOrderType,
                onTap: () => _editSimpleField(
                  title: "Default Order Type",
                  currentValue: _defaultOrderType,
                  onSaved: (v) => _defaultOrderType = v,
                ),
              ),
              _infoTile(
                icon: Icons.attach_money,
                iconBg: accentGreen,
                title: "Default Amount Currency",
                value: _defaultCurrency,
                onTap: () => _editSimpleField(
                  title: "Default Amount Currency",
                  currentValue: _defaultCurrency,
                  onSaved: (v) => _defaultCurrency = v,
                ),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // ---------------- Account ----------------
            _sectionTitle("Account"),
            _sectionCard([
              _planTile(),
              _infoTile(
                icon: Icons.account_balance_wallet_outlined,
                iconBg: accentGreen,
                title: "Demo Balance",
                value: "",
                trailing: Text(
                  "\$${_demoBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {},
              ),
              _infoTile(
                icon: Icons.lock_outline,
                iconBg: const Color(0xFF334155),
                title: "Change Password",
                value: "",
                onTap: _showPasswordDialog,
              ),
              _infoTile(
                icon: Icons.logout,
                iconBg: Colors.red.shade900,
                title: "Logout",
                value: "",
                titleColor: Colors.red,
                onTap: _logout,
                isLast: true,
              ),
            ]),

            const SizedBox(height: 12),

            // Delete account â€” subtle, professional destructive action
            Center(
              child: TextButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: const Text(
                  "Delete Account",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- Demo Mode banner ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: accentGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "You're trading in Demo Mode",
                          style: TextStyle(
                            color: accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "No real money is used.\nPractice and build your skills risk-free.",
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "DEMO",
                              style: TextStyle(
                                color: accentGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------- Reusable UI pieces ----------------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
    Color titleColor = textPrimary,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconBg, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        value,
                        style: const TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _planTile() {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium_outlined,
                  color: accentPurple, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Subscription Plan",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildBadge("PRO", accentPurple),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _plan,
                      style: const TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}