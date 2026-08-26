import 'package:flutter/material.dart';

import '../screens/ai_coach_screen.dart';
import '../screens/learning_path_screen.dart';
import '../service/ai_learning_store.dart';
import '../theme_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    AiLearningStore.instance.bind();
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  IconData _icon(IconKind kind) {
    switch (kind) {
      case IconKind.briefing:
        return Icons.wb_twilight;
      case IconKind.review:
        return Icons.rate_review_outlined;
      case IconKind.lesson:
        return Icons.menu_book_outlined;
      case IconKind.risk:
        return Icons.shield_outlined;
      case IconKind.streak:
        return Icons.local_fire_department;
    }
  }

  Color _color(IconKind kind) {
    switch (kind) {
      case IconKind.briefing:
        return const Color(0xFF8B5CF6);
      case IconKind.review:
        return const Color(0xFF22C55E);
      case IconKind.lesson:
        return const Color(0xFF3B82F6);
      case IconKind.risk:
        return const Color(0xFFF59E0B);
      case IconKind.streak:
        return const Color(0xFFF97316);
    }
  }

  void _open(BuildContext context, AiNotice n) {
    if (n.kind == IconKind.lesson) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningPathScreen()));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AiCoachScreen(seed: n.subtitle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.scaffold,
        elevation: 0,
        title: Text("Notifications", style: TextStyle(color: colors.text)),
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: ListenableBuilder(
        listenable: AiLearningStore.instance,
        builder: (context, _) {
          final notifications = AiLearningStore.instance.notices;
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                "No coach notices yet. Open Home for today’s briefing.",
                style: TextStyle(color: colors.muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final color = _color(n.kind);
              return InkWell(
                onTap: () => _open(context, n),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_icon(n.kind), color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                color: colors.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.subtitle,
                              style: TextStyle(color: colors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _ago(n.time),
                        style: TextStyle(color: colors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
