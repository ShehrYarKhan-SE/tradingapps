import 'package:flutter/material.dart';

import '../content/smc/smc_catalog.dart';
import '../content/smc/smc_models.dart';
import '../service/ai_learning_store.dart';
import 'smc_topic_screen.dart';

class SmcLibraryScreen extends StatelessWidget {
  const SmcLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AiLearningStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final read = store.smcReadIds;
        return Scaffold(
          backgroundColor: const Color(0xFF07061A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF07061A),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Teach Me Trading',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF101838),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00A3FF).withValues(alpha: 0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ICT / SMC concepts',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open one topic at a time. Each lesson is a US100 example, not a live signal. '
                      '${read.length}/${smcTopics.length} studied.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: smcTopics.isEmpty ? 0 : read.length / smcTopics.length,
                        minHeight: 7,
                        color: const Color(0xFF22C55E),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ],
                ),
              ),
              for (final group in smcGroups()) ...[
                const SizedBox(height: 22),
                Text(
                  group.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                ...smcTopics.where((t) => t.group == group).map(
                      (t) => _TopicTile(
                        topic: t,
                        read: read.contains(t.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SmcTopicScreen(topicId: t.id),
                            ),
                          );
                        },
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.read,
    required this.onTap,
  });

  final SmcTopic topic;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF101838),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (read ? const Color(0xFF22C55E) : const Color(0xFF6D5CFF))
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    topic.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: read ? const Color(0xFF4ADE80) : const Color(0xFFC4B5FD),
                      fontSize: topic.code.length > 4 ? 8 : 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        topic.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  read ? Icons.check_circle : Icons.chevron_right,
                  color: read ? const Color(0xFF22C55E) : Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
