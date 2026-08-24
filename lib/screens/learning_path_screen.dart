import 'package:flutter/material.dart';

import '../service/ai_coach_service.dart';
import '../service/ai_learning_store.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key, this.onPracticeTrade});

  final VoidCallback? onPracticeTrade;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  String? _openId;
  int? _picked;
  bool? _correct;

  @override
  Widget build(BuildContext context) {
    final store = AiLearningStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final open = _openId == null
            ? null
            : AiLearningStore.lessons.where((l) => l.id == _openId).firstOrNull;
        return Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B1120),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              open == null ? 'Learning Path' : open.title,
              style: const TextStyle(color: Colors.white),
            ),
            leading: open == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() {
                      _openId = null;
                      _picked = null;
                      _correct = null;
                    }),
                  ),
          ),
          body: open == null ? _list(store) : _lesson(store, open),
        );
      },
    );
  }

  Widget _list(AiLearningStore store) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '${store.completedCount} / ${store.totalLessons} lessons · streak ${store.streakDays} day${store.streakDays == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: store.progress,
            minHeight: 8,
            color: const Color(0xFF22C55E),
            backgroundColor: Colors.white12,
          ),
        ),
        const SizedBox(height: 16),
        ...AiLearningStore.lessons.map((l) {
          final done = store.completedIds.contains(l.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => setState(() {
                _openId = l.id;
                _picked = null;
                _correct = null;
              }),
              tileColor: const Color(0xFF141B2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: Icon(
                done ? Icons.check_circle : Icons.menu_book_outlined,
                color: done ? const Color(0xFF22C55E) : const Color(0xFF8B5CF6),
              ),
              title: Text(l.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                done ? 'Completed' : 'Tap to study + quiz',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            ),
          );
        }),
      ],
    );
  }

  Widget _lesson(AiLearningStore store, LessonItem lesson) {
    final done = store.completedIds.contains(lesson.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(lesson.body, style: const TextStyle(color: Colors.white70, height: 1.45, fontSize: 15)),
        const SizedBox(height: 20),
        const Text('Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(lesson.question, style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 10),
        ...List.generate(lesson.options.length, (i) {
          final selected = _picked == i;
          Color border = Colors.white12;
          if (_correct != null && selected) {
            border = _correct! ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _picked = i;
                  _correct = i == lesson.answerIndex;
                });
                if (i == lesson.answerIndex &&
                    !store.completedIds.contains(lesson.id)) {
                  store.completeLesson(lesson.id);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141B2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text(lesson.options[i], style: const TextStyle(color: Colors.white)),
              ),
            ),
          );
        }),
        if (_correct == true) ...[
          const SizedBox(height: 8),
          Text(
            AiCoachService.instance.lessonFollowUp(lesson.id),
            style: const TextStyle(color: Color(0xFFA78BFA), height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(lesson.practiceHint, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () {
              Navigator.pop(context);
              widget.onPracticeTrade?.call();
            },
            child: const Text('Take the suggested demo trade'),
          ),
        ] else if (_correct == false)
          const Text('Not quite — try another option.', style: TextStyle(color: Color(0xFFEF4444))),
        if (done && _correct != true) ...[
          const SizedBox(height: 16),
          Text(lesson.practiceHint, style: const TextStyle(color: Colors.white54)),
        ],
      ],
    );
  }
}
