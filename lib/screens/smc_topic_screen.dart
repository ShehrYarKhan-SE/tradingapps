import 'package:flutter/material.dart';

import '../content/smc/smc_catalog.dart';
import '../service/ai_learning_store.dart';
import '../widgets/smc_chart_illustration.dart';

class SmcTopicScreen extends StatefulWidget {
  const SmcTopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<SmcTopicScreen> createState() => _SmcTopicScreenState();
}

class _SmcTopicScreenState extends State<SmcTopicScreen> {
  @override
  void initState() {
    super.initState();
    AiLearningStore.instance.markSmcRead(widget.topicId);
  }

  @override
  Widget build(BuildContext context) {
    final topic = smcTopicById(widget.topicId);
    if (topic == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF07061A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF07061A),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('Topic not found', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07061A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07061A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          topic.code,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          Text(
            topic.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            topic.subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
          ),
          const SizedBox(height: 16),
          SmcChartCard(chart: topic.chart),
          const SizedBox(height: 22),
          _Section(title: 'What it is', body: topic.what),
          _Section(title: 'How to spot it', body: topic.spot),
          _Section(title: 'How it is used', body: topic.use),
          _Section(title: 'On US100', body: topic.us100),
          _Section(title: 'Common mistake', body: topic.mistake),
          const SizedBox(height: 8),
          Text(
            'Educational only — not a buy or sell signal. Practice on the demo chart.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
