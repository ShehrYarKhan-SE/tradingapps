import 'dart:ui';

import 'package:flutter/material.dart';

import '../service/ai_coach_service.dart';
import '../service/ai_learning_store.dart';
import 'smc_library_screen.dart';
import 'smc_quiz_library_screen.dart';

const _kNavy = Color(0xFF07061A);
const _kGlass = Color(0x99101838);
const _kNeon = Color(0xFF00A3FF);
const _kViolet = Color(0xFF6D5CFF);

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key, this.seed, this.embedded = false});

  final String? seed;
  final bool embedded;

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _ChatMsg {
  final bool me;
  final String text;
  final DateTime time;

  const _ChatMsg({required this.me, required this.text, required this.time});
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _messages = <_ChatMsg>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final intro = widget.seed ??
        'Hi — I am your Virtual Trading AI coach. Ask anything about this demo account.\n\n${AiCoachService.instance.dailyBriefing()}';
    _messages.add(_ChatMsg(me: false, text: intro, time: DateTime.now()));
    AiLearningStore.instance.markPracticed();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _fmt(DateTime t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    final lower = text.toLowerCase();
    if (lower.contains('teach me trading') ||
        lower.contains('teach me smc') ||
        lower.contains('ict concept')) {
      _openSmcLibrary();
      return;
    }
    if (lower.contains('quiz') ||
        lower.contains('quize') ||
        lower.contains('practice tips')) {
      _openQuiz();
      return;
    }
    setState(() {
      _messages.add(_ChatMsg(me: true, text: text, time: DateTime.now()));
      _busy = true;
    });
    _ctrl.clear();
    _scrollToEnd();
    AiLearningStore.instance.markPracticed();

    final prior = _messages.where((m) => m.me).map((m) => m.text).toList();
    if (prior.isNotEmpty) prior.removeLast();

    final answer = await AiCoachService.instance.ask(text, prior: prior);
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMsg(me: false, text: answer, time: DateTime.now()));
      _busy = false;
    });
    _scrollToEnd();
  }

  void _openSmcLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmcLibraryScreen()),
    );
  }

  void _openQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmcQuizLibraryScreen()),
    );
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
    final body = Stack(
      fit: StackFit.expand,
      children: [
        const _CoachBackdrop(),
        Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  const _HeroCard(),
                  const SizedBox(height: 18),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.school_rounded,
                          color: const Color(0xFF34D399),
                          title: 'Teach Me Trading',
                          subtitle: 'ICT / SMC topics, one at a time.',
                          onTap: _openSmcLibrary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFFFBBF24),
                          title: 'Analyze My Trade',
                          subtitle: 'Review your demo trades & improve.',
                          onTap: _busy ? null : () => _send('Review my last trade'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.quiz_rounded,
                          color: const Color(0xFFC084FC),
                          title: 'Quiz',
                          subtitle: 'US100 replay — Buy or Sell.',
                          onTap: _openQuiz,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      AiCoachAvatar(size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Ask Virtual Trading AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._messages.map(_bubble),
                  if (_busy) const _TypingBubble(),
                ],
              ),
            ),
            _Composer(
              ctrl: _ctrl,
              focus: _focus,
              busy: _busy,
              onSend: () => _send(_ctrl.text),
            ),
          ],
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('AI Coach', style: TextStyle(color: Colors.white)),
      ),
      body: body,
    );
  }

  Widget _bubble(_ChatMsg m) {
    if (m.me) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: _kNeon.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m.text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(m.time),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiCoachAvatar(size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: _kGlass,
                        border: Border.all(color: _kNeon.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        m.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(m.time),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachBackdrop extends StatelessWidget {
  const _CoachBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _kNavy),
        Opacity(
          opacity: 0.55,
          child: Image.asset(
            'assets/branding/ai_coach_bg.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0.85, 0),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xA607061A),
                Color(0x6607061A),
                Color(0xF207061A),
              ],
              stops: [0.0, 0.38, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 148,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/branding/ai_coach_bg.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.9, 0),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF207061A),
                    Color(0x990A0A23),
                    Color(0x220A0A23),
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 110, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'AI Coach',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your personal trading assistant',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.45)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)),
                        SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            decoration: BoxDecoration(
              color: _kGlass,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kNeon.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool busy;
  final VoidCallback onSend;

  const _Composer({
    required this.ctrl,
    required this.focus,
    required this.busy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: _kGlass,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _kNeon.withValues(alpha: 0.22)),
                  ),
                  child: TextField(
                    controller: ctrl,
                    focusNode: focus,
                    enabled: !busy,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about trading...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      suffixIcon: Icon(
                        Icons.mic_none_rounded,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: busy ? null : onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kNeon, _kViolet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kNeon.withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AiCoachAvatar(size: 32),
          SizedBox(width: 8),
          Text('Thinking…', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class AiCoachAvatar extends StatelessWidget {
  final double size;

  const AiCoachAvatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _kNeon.withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/branding/ai_coach_bg.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0.92, 0),
        ),
      ),
    );
  }
}
