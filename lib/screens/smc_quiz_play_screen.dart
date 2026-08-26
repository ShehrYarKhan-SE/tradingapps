import 'dart:async';

import 'package:flutter/material.dart';

import '../content/smc/smc_catalog.dart';
import '../content/smc/smc_quiz_engine.dart';
import '../service/ai_learning_store.dart';
import '../widgets/tv_replay_chart.dart';

enum _Phase { ready, replay, done }

class SmcQuizPlayScreen extends StatefulWidget {
  const SmcQuizPlayScreen({
    super.key,
    required this.topicId,
  });

  final String topicId;

  @override
  State<SmcQuizPlayScreen> createState() => _SmcQuizPlayScreenState();
}

class _SmcQuizPlayScreenState extends State<SmcQuizPlayScreen> {
  late final List<QuizIntent> _round;
  late final List<int> _salts;
  late QuizClip _clip;
  int _index = 0;
  _Phase _phase = _Phase.ready;
  int _visible = 0;
  QuizIntent? _picked;
  bool? _won;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _round = shuffledQuizRound();
    _salts = List.generate(3, (_) => newQuizSalt());
    _boot();
  }

  void _boot() {
    _clip = buildQuizClip(
      topicId: widget.topicId,
      intent: _round[_index],
      salt: _salts[_index],
    );
    _phase = _Phase.ready;
    _visible = _clip.freezeIndex + 1;
    _picked = null;
    _won = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _choose(QuizIntent pick) {
    if (_phase != _Phase.ready) return;
    setState(() {
      _picked = pick;
      _phase = _Phase.replay;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 170), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_visible >= _clip.candles.length) {
        t.cancel();
        final won = pick == _clip.intent;
        setState(() {
          _phase = _Phase.done;
          _won = won;
        });
        AiLearningStore.instance.recordQuiz(quizRecordKey(widget.topicId, _clip.intent), won);
        return;
      }
      setState(() => _visible += 1);
    });
  }

  bool get _hasNext => _index < _round.length - 1;

  void _nextQuiz() {
    _timer?.cancel();
    setState(() {
      _index += 1;
      _boot();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = smcTopicById(widget.topicId);
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131722),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          topic?.code ?? 'Quiz',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: [
          _progress(),
          const SizedBox(height: 10),
          Text(
            topic?.title ?? 'Quiz',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _clip.prompt,
            style: const TextStyle(color: Color(0xFFB2B5BE), height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TvReplayChart(
            candles: _clip.candles,
            visibleCount: _visible,
            marks: _phase == _Phase.done ? _clip.marks : const [],
            nowIndex: _clip.freezeIndex,
            entryIndex: _picked == null ? null : _clip.freezeIndex,
            entryPick: _picked,
            height: 332,
          ),
          const SizedBox(height: 10),
          if (_phase == _Phase.ready) ...[
            const Text(
              'Future candles are locked. Read the tape, then choose.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF787B86), fontSize: 11),
            ),
            const SizedBox(height: 10),
            _buttons(),
          ],
          if (_phase == _Phase.replay)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Replaying…',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF26C6DA), fontWeight: FontWeight.w800),
              ),
            ),
          if (_phase == _Phase.done) _result(),
        ],
      ),
    );
  }

  Widget _progress() {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= _index
                    ? const Color(0xFF2962FF)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (i != 2) const SizedBox(width: 6),
        ],
        const SizedBox(width: 10),
        Text(
          '${_index + 1} / 3',
          style: const TextStyle(color: Color(0xFF787B86), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buttons() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _Btn(
            label: 'SELL',
            color: const Color(0xFFEF5350),
            onTap: () => _choose(QuizIntent.sell),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _Btn(
            label: 'RANG',
            color: const Color(0xFFFFD54F),
            small: true,
            onTap: () => _choose(QuizIntent.range),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _Btn(
            label: 'BUY',
            color: const Color(0xFF26A69A),
            onTap: () => _choose(QuizIntent.buy),
          ),
        ),
      ],
    );
  }

  Widget _result() {
    final won = _won == true;
    final pts = _clip.points;
    final you = _picked?.label ?? '';
    final actual = _clip.intent.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (won ? const Color(0xFF26A69A) : const Color(0xFFEF5350)).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: won ? const Color(0xFF26A69A) : const Color(0xFFEF5350)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                won ? 'Correct read' : 'Different delivery',
                style: TextStyle(
                  color: won ? const Color(0xFF80CBC4) : const Color(0xFFEF9A9A),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _clip.intent == QuizIntent.range
                    ? 'You pressed $you. Price stayed in balance — RANG was the answer.'
                    : 'You pressed $you. Replay answer: $actual  (${pts >= 0 ? '+' : ''}${pts.toStringAsFixed(1)} pts from NOW).',
                style: const TextStyle(color: Color(0xFFD1D4DC), height: 1.4, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Why this chart',
          style: TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          _clip.theory,
          style: const TextStyle(color: Color(0xFFB2B5BE), height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _hasNext ? _nextQuiz : () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
                child: Text(_hasNext ? 'Next quiz' : 'Back to topic list'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.color,
    required this.onTap,
    this.small = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: small ? 40 : 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.75)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: small ? 12 : 15,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
