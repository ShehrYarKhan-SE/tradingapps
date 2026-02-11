import 'package:flutter/material.dart';

class MobileSettings extends StatelessWidget {
  const MobileSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Profile Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Example', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('trader@example.com', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('PRO Account', style: TextStyle(color: Colors.purple[400], fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _buildSettingsGroup('Account', [
            {'icon': Icons.person, 'label': 'Profile', 'subtitle': 'Manage your account'},
            {'icon': Icons.shield, 'label': 'Security', 'subtitle': '2FA, Password'},
            {'icon': Icons.notifications, 'label': 'Notifications', 'subtitle': 'Push, Email alerts'},
          ]),

          _buildSettingsGroup('Preferences', [
            {'icon': Icons.dark_mode, 'label': 'Dark Mode', 'subtitle': 'Currently enabled', 'hasSwitch': true},
            {'icon': Icons.language, 'label': 'Language', 'subtitle': 'English'},
            {'icon': Icons.vibration, 'label': 'Feedback', 'subtitle': 'Vibration on actions', 'hasSwitch': true},
          ]),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red[400], size: 20),
                  const SizedBox(width: 8),
                  Text('Log Out', style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          Text('AI Based Virtual Trading Apps', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: i < items.length - 1
                        ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData, color: Colors.grey[400], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            Text(item['subtitle'] as String, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      ),
                      if (item['hasSwitch'] == true)
                        Switch(value: true, onChanged: (_) {}, activeColor: const Color(0xFF8B5CF6))
                      else
                        Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
                    ],
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