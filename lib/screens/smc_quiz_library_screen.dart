import 'package:flutter/material.dart';

import '../content/smc/smc_catalog.dart';
import '../content/smc/smc_models.dart';
import '../content/smc/smc_quiz_engine.dart';
import '../service/ai_learning_store.dart';
import 'smc_quiz_play_screen.dart';

class SmcQuizLibraryScreen extends StatelessWidget {
  const SmcQuizLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AiLearningStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0C0E14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF131722),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Quiz',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3 US100 charts per topic',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Each topic has 3 random US100 charts. Open a topic, read the tape, then press SELL · RANG · BUY — the chart will not tell you which one it is.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.58), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${store.smcQuizWins} / ${store.smcQuizPlays} correct',
                      style: const TextStyle(color: Color(0xFF80CBC4), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
              for (final group in smcGroups()) ...[
                const SizedBox(height: 22),
                Text(
                  group.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                ...smcTopics.where((t) => t.group == group).map((t) => _TopicQuizzes(topic: t)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TopicQuizzes extends StatelessWidget {
  const _TopicQuizzes({required this.topic});

  final SmcTopic topic;

  @override
  Widget build(BuildContext context) {
    final store = AiLearningStore.instance;
    var done = 0;
    for (final i in QuizIntent.values) {
      if (store.quizPlays(quizRecordKey(topic.id, i)) > 0) done++;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SmcQuizPlayScreen(
                  topicId: topic.id,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2E39)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2962FF).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    topic.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF90CAF9),
                      fontSize: topic.code.length > 4 ? 8 : 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$done / 3 quizzes · unique charts',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
