import 'package:flutter/material.dart';

// ===========================================================
// All secondary menu screens combined into ONE file:
// Security, Wallet, Rewards, VIP Status, Help Center.
// ===========================================================


class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFAEnabled = false;
  bool _biometricEnabled = true;
  bool _loginAlerts = true;

  static const _bg = Color(0xFF0D0D0F);
  static const _card = Color(0xFF1A1A1F);
  static const _accent = Color(0xFF22C55E);

  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(currentCtrl, 'Current password'),
              const SizedBox(height: 10),
              _dialogField(newCtrl, 'New password'),
              const SizedBox(height: 10),
              _dialogField(confirmCtrl, 'Confirm new password'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              if (newCtrl.text.isEmpty || newCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 20),
      child: Text(text,
          style: TextStyle(
              color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: _accent),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Security', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('AUTHENTICATION'),
          _switchTile(
            icon: Icons.verified_user,
            color: _accent,
            title: 'Two-Factor Authentication',
            subtitle: _twoFAEnabled ? 'Enabled — your account is protected' : 'Add an extra layer of security',
            value: _twoFAEnabled,
            onChanged: (v) => setState(() => _twoFAEnabled = v),
          ),
          _switchTile(
            icon: Icons.fingerprint,
            color: const Color(0xFF3B82F6),
            title: 'Biometric Login',
            subtitle: 'Use fingerprint / face unlock',
            value: _biometricEnabled,
            onChanged: (v) => setState(() => _biometricEnabled = v),
          ),
          _switchTile(
            icon: Icons.notifications_active,
            color: const Color(0xFFF59E0B),
            title: 'New Login Alerts',
            subtitle: 'Get notified on unrecognized sign-ins',
            value: _loginAlerts,
            onChanged: (v) => setState(() => _loginAlerts = v),
          ),
          _sectionTitle('PASSWORD'),
          _actionTile(
            icon: Icons.lock_reset,
            color: const Color(0xFFEC4899),
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: _changePassword,
          ),
        ],
      ),
    );
  }
}


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 12480.35;

  static const _bg = Color(0xFF0D0D0F);
  static const _card = Color(0xFF1A1A1F);
  static const _purple = Color(0xFF8B5CF6);

  void _showAmountSheet({required String title, required Color color, required bool isDeposit}) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 22),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: Colors.white, fontSize: 22),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final amount = double.tryParse(ctrl.text) ?? 0;
                    if (amount <= 0) return;
                    setState(() => _balance += isDeposit ? amount : -amount);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${isDeposit ? 'Deposited' : 'Withdrew'} \$${amount.toStringAsFixed(2)}')),
                    );
                  },
                  child: Text(isDeposit ? 'Deposit' : 'Withdraw', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTile(String label, String amount, bool isPositive, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isPositive ? Colors.green : Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(
            '${isPositive ? '+' : '-'}\$$amount',
            style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Wallet', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _purple.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('\$${_balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAmountSheet(title: 'Deposit Funds', color: Colors.green, isDeposit: true),
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text('Deposit', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAmountSheet(title: 'Withdraw Funds', color: Colors.redAccent, isDeposit: false),
                        icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                        label: const Text('Withdraw', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('RECENT ACTIVITY',
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          _historyTile('Deposit', '2,500.00', true, Icons.arrow_downward),
          _historyTile('Withdrawal', '400.00', false, Icons.arrow_upward),
          _historyTile('Deposit', '1,000.00', true, Icons.arrow_downward),
        ],
      ),
    );
  }
}


class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _Reward {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color color;
  bool claimed;

  _Reward({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    this.claimed = false,
  });
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const _bg = Color(0xFF0D0D0F);
  static const _card = Color(0xFF1A1A1F);
  static const _orange = Color(0xFFF59E0B);

  final List<_Reward> _rewards = [
    _Reward(
      title: 'Daily Login Bonus',
      subtitle: 'Come back every day to claim',
      amount: '\$5.00',
      icon: Icons.calendar_today,
      color: Colors.blue,
    ),
    _Reward(
      title: 'Welcome Bonus',
      subtitle: 'For joining TradeMaster AI',
      amount: '\$50.00',
      icon: Icons.celebration,
      color: Colors.pink,
    ),
    _Reward(
      title: 'Referral Bonus',
      subtitle: 'Invite a friend to earn',
      amount: '\$20.00',
      icon: Icons.group_add,
      color: Colors.green,
      claimed: true,
    ),
    _Reward(
      title: '7-Day Streak',
      subtitle: 'Trade 7 days in a row',
      amount: '\$15.00',
      icon: Icons.local_fire_department,
      color: Colors.deepOrange,
    ),
  ];

  void _claim(_Reward reward) {
    if (reward.claimed) return;
    setState(() => reward.claimed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${reward.amount} added to your wallet 🎉')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimableCount = _rewards.where((r) => !r.claimed).length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Rewards', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEA580C)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$claimableCount bonuses available',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Claim them before they expire',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._rewards.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: r.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(r.icon, color: r.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(r.subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(r.amount, style: TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: r.claimed ? Colors.grey[800] : _orange,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _claim(r),
                  child: Text(r.claimed ? 'Claimed' : 'Claim',
                      style: TextStyle(color: r.claimed ? Colors.grey[400] : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}


class VipStatusScreen extends StatelessWidget {
  const VipStatusScreen({super.key});

  static const _bg = Color(0xFF0D0D0F);
  static const _card = Color(0xFF1A1A1F);
  static const _gold = Color(0xFFFACC15);

  Widget _perkTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: _gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: _gold, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double progress = 0.68; // trading volume progress toward next tier

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('VIP Status', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFACC15), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.black, size: 26),
                    SizedBox(width: 8),
                    Text('Pro Member', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('You are enjoying premium trading perks',
                    style: TextStyle(color: Colors.black87, fontSize: 12)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Progress to Elite', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('68%', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('YOUR PERKS', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          _perkTile(Icons.speed, 'Priority Order Execution', 'Faster trade matching'),
          _perkTile(Icons.percent, 'Reduced Trading Fees', '0.05% instead of 0.10%'),
          _perkTile(Icons.support_agent, '24/7 Priority Support', 'Dedicated help line'),
          _perkTile(Icons.analytics, 'Advanced Analytics', 'Deeper market insights'),
        ],
      ),
    );
  }
}


class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _bg = Color(0xFF0D0D0F);
  static const _card = Color(0xFF1A1A1F);
  static const _cyan = Color(0xFF06B6D4);

  static const _faqs = [
    {
      'q': 'How do I deposit funds?',
      'a': 'Go to Wallet from the menu and tap Deposit, then enter the amount you want to add.'
    },
    {
      'q': 'How do I switch between demo and live mode?',
      'a': 'Use the mode switch at the top of the Home screen to toggle between Demo and Live trading.'
    },
    {
      'q': 'How do I enable Two-Factor Authentication?',
      'a': 'Go to Security from the menu and turn on the Two-Factor Authentication switch.'
    },
    {
      'q': 'When are rewards credited?',
      'a': 'Rewards are credited instantly to your wallet balance as soon as you tap Claim.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Help Center', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening live chat...')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Column(
                        children: const [
                          Icon(Icons.chat_bubble_outline, color: _cyan, size: 26),
                          SizedBox(height: 8),
                          Text('Live Chat', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening email support...')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Column(
                        children: const [
                          Icon(Icons.email_outlined, color: Colors.orange, size: 26),
                          SizedBox(height: 8),
                          Text('Email Us', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          ..._faqs.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: _cyan,
                collapsedIconColor: Colors.grey,
                title: Text(f['q']!, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(f['a']!, style: TextStyle(color: Colors.grey[400], fontSize: 12.5, height: 1.4)),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}