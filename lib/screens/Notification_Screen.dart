import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color bgColor = Color(0xFF0B1120);
  static const Color cardColor = Color(0xFF141B2E);
  static const Color borderColor = Color(0xFF232B41);

  @override
  Widget build(BuildContext context) {
    // TODO: replace this sample list with your real notifications data
    final notifications = [
      {
        'icon': Icons.trending_up,
        'color': const Color(0xFF22C55E),
        'title': 'BTC/USDT is up 2.34%',
        'subtitle': 'Price crossed \$42,800',
        'time': '5m ago',
      },
      {
        'icon': Icons.emoji_events_outlined,
        'color': const Color(0xFFF59E0B),
        'title': 'Daily streak: 7 days!',
        'subtitle': 'Keep practicing to extend your streak',
        'time': '1h ago',
      },
      {
        'icon': Icons.smart_toy_outlined,
        'color': const Color(0xFF8B5CF6),
        'title': 'AI Coach has a new tip for you',
        'subtitle': 'Tap to see personalized insights',
        'time': '3h ago',
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Text(
          "No notifications yet",
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (n['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(n['icon'] as IconData,
                      color: n['color'] as Color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n['subtitle'] as String,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  n['time'] as String,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}