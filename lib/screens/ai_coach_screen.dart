import 'package:flutter/material.dart';

import '../service/ai_coach_service.dart';
import '../service/ai_learning_store.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key, this.seed});

  final String? seed;

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _messages = <({bool me, String text})>[];
  bool _busy = false;

  static const _prompts = [
    'Daily briefing',
    'Review my last trade',
    'Explain my open positions',
    'How should I size lots?',
    'Explain the US100 chart',
  ];

  @override
  void initState() {
    super.initState();
    final intro = widget.seed ??
        'Hi — I am your Virtual Trading AI coach. Ask anything about this demo account.\n\n${AiCoachService.instance.dailyBriefing()}';
    _messages.add((me: false, text: intro));
    AiLearningStore.instance.markPracticed();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _messages.add((me: true, text: text));
      _busy = true;
    });
    _ctrl.clear();
    _scrollToEnd();
    AiLearningStore.instance.markPracticed();

    final prior = _messages
        .where((m) => m.me)
        .map((m) => m.text)
        .toList();
    if (prior.isNotEmpty) prior.removeLast();

    final answer = await AiCoachService.instance.ask(text, prior: prior);
    if (!mounted) return;
    setState(() {
      _messages.add((me: false, text: answer));
      _busy = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('AI Coach', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Free AI in the box below · educational only, not financial advice',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _prompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return ActionChip(
                  label: Text(_prompts[i], style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFF1E1B4B),
                  labelStyle: const TextStyle(color: Color(0xFFC4B5FD)),
                  side: BorderSide(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
                  onPressed: _busy ? null : () => _send(_prompts[i]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (_, i) {
                if (_busy && i == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _TypingBubble(),
                    ),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: m.me ? const Color(0xFF2563EB) : const Color(0xFF141B2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      enabled: !_busy,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Ask the free AI anything…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF141B2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : () => _send(_ctrl.text),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      disabledBackgroundColor: const Color(0xFF4C1D95),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Thinking…',
        style: TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}
