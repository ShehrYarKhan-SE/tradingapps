import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'ai_coach_service.dart';
import 'demo_trade_service.dart';
import 'user_account_store.dart';

class AiNotice {
  final String id;
  final IconKind kind;
  final String title;
  final String subtitle;
  final DateTime time;

  const AiNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'time': time.toIso8601String(),
      };

  factory AiNotice.fromJson(Map<String, dynamic> json) => AiNotice(
        id: json['id'] as String,
        kind: IconKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => IconKind.briefing,
        ),
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      );
}

enum IconKind { briefing, review, lesson, risk, streak }

class LessonItem {
  final String id;
  final String title;
  final String body;
  final String question;
  final List<String> options;
  final int answerIndex;
  final String practiceHint;

  const LessonItem({
    required this.id,
    required this.title,
    required this.body,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.practiceHint,
  });
}

class AiLearningStore extends ChangeNotifier {
  AiLearningStore._();
  static final AiLearningStore instance = AiLearningStore._();

  static const lessons = <LessonItem>[
    LessonItem(
      id: 'demo',
      title: 'The demo is a gym',
      body:
          'Virtual money lets you practice process: size, stop, and review. A big demo P/L does not mean you are ready for live funds. Treat each fill as a drill.',
      question: 'What is the demo account mainly for?',
      options: [
        'Predicting tomorrow’s US100 close',
        'Practicing size, stops, and reviews',
        'Guaranteeing live profits',
      ],
      answerIndex: 1,
      practiceHint: 'Open Trade and place 0.02 lots with a stop — just to feel the fill.',
    ),
    LessonItem(
      id: 'spread',
      title: 'Bid, ask, and spread',
      body:
          'You buy at ask and sell at bid. The gap is the spread — a cost you pay immediately. Tiny targets can be eaten by that cost before the idea even works.',
      question: 'If you tap BUY, which price fills?',
      options: ['Bid', 'Ask', 'Yesterday’s close'],
      answerIndex: 1,
      practiceHint: 'Look at the red and blue prices on the Trade bar before you tap.',
    ),
    LessonItem(
      id: 'lots',
      title: 'Lots are the volume knob',
      body:
          'Larger lots multiply both wins and losses. On this demo, margin is about \$100 per lot. If a stop-out would sting, the lot size is too high for practice.',
      question: 'What should you do if a planned stop would lose a large slice of the demo?',
      options: [
        'Add a second trade the same way',
        'Cut lots or widen nothing — reduce size',
        'Remove the stop so it cannot hit',
      ],
      answerIndex: 1,
      practiceHint: 'Use 0.01–0.04 lots until reviews look calm.',
    ),
    LessonItem(
      id: 'stops',
      title: 'Stop loss is the lesson plan',
      body:
          'A stop is where the idea is wrong. Without it, a practice trade can become a hope trade. Take-profit is optional; a stop is how you cap the drill.',
      question: 'A stop loss is best described as…',
      options: [
        'The price where the idea is invalid',
        'A way to lock guaranteed profit',
        'Only for losing traders',
      ],
      answerIndex: 0,
      practiceHint: 'Fill SL (price or points) on the Trade bar, then enter.',
    ),
    LessonItem(
      id: 'overtrade',
      title: 'One idea at a time',
      body:
          'Stacking three US100 positions the same direction is one bet, not three analyses. If the first trade is open, adding more is usually emotion.',
      question: 'You already have two open BUY trades. The healthy next step is usually…',
      options: [
        'Buy a third lot to average',
        'Manage or close what is open',
        'Sell twice as much to hedge blindly',
      ],
      answerIndex: 1,
      practiceHint: 'Keep a maximum of one new idea until something is closed.',
    ),
    LessonItem(
      id: 'review',
      title: 'Close, then read the review',
      body:
          'After a close, the coach writes why it likely helped or hurt: size, missing stops, hold time. Read it on Portfolio. Change one thing next time — not everything.',
      question: 'After a demo close you should…',
      options: [
        'Immediately reverse to “get it back”',
        'Read the AI review and pick one change',
        'Ignore losers and only screenshot winners',
      ],
      answerIndex: 1,
      practiceHint: 'Close a small trade, then open Portfolio and read the review line.',
    ),
  ];

  String? _uid;
  String? _appliedUpdatedAt;
  bool _listeningStore = false;
  final Set<String> completedIds = {};
  int streakDays = 0;
  String? lastActionDay;
  String briefing = '';
  String? briefingDay;
  final List<AiNotice> notices = [];
  bool _listeningDemo = false;
  String? _lastReviewTradeId;

  int get completedCount => completedIds.length;
  int get totalLessons => lessons.length;
  double get progress => totalLessons == 0 ? 0 : completedCount / totalLessons;

  LessonItem? get nextLesson {
    for (final l in lessons) {
      if (!completedIds.contains(l.id)) return l;
    }
    return lessons.last;
  }

  Future<void> bind() async {
    final store = UserAccountStore.instance;
    await store.bindToCurrentUser();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? store.uid;
    if (uid == null) {
      resetMemory();
      return;
    }
    _uid = uid;
    if (!_listeningStore) {
      _listeningStore = true;
      store.addListener(_onStore);
    }
    _applyFromStore(force: true);
    _listenDemo();
    refreshBriefing();
    _onDemo();
    notifyListeners();
  }

  void _onStore() {
    if (_uid == null || _uid != UserAccountStore.instance.uid) return;
    _applyFromStore();
  }

  void resetMemory() {
    _uid = null;
    _appliedUpdatedAt = null;
    completedIds.clear();
    streakDays = 0;
    lastActionDay = null;
    briefing = '';
    briefingDay = null;
    notices.clear();
    _lastReviewTradeId = null;
    notifyListeners();
  }

  void _listenDemo() {
    if (_listeningDemo) return;
    _listeningDemo = true;
    DemoTradeService.instance.addListener(_onDemo);
  }

  void _onDemo() {
    final trades = DemoTradeService.instance.trades;
    if (trades.isEmpty) return;
    final latest = trades.first;
    if (latest.id == _lastReviewTradeId) return;
    if (latest.review != null && latest.review!.isNotEmpty) {
      _lastReviewTradeId = latest.id;
      return;
    }
    final text = AiCoachService.instance.reviewTrade(latest);
    DemoTradeService.instance.setTradeReview(latest.id, text);
    _lastReviewTradeId = latest.id;
    markPracticed();
    pushNotice(
      AiNotice(
        id: 'rev_${latest.id}',
        kind: IconKind.review,
        title: latest.pnl >= 0 ? 'AI review: winner' : 'AI review: loser',
        subtitle: text.length > 90 ? '${text.substring(0, 90)}…' : text,
        time: DateTime.now(),
      ),
    );
  }

  void refreshBriefing({bool force = false}) {
    final day = _dayKey(DateTime.now());
    if (!force && briefingDay == day && briefing.isNotEmpty) return;
    briefing = AiCoachService.instance.dailyBriefing();
    briefingDay = day;
    final exists = notices.any((n) => n.id == 'brief_$day');
    if (!exists) {
      notices.insert(
        0,
        AiNotice(
          id: 'brief_$day',
          kind: IconKind.briefing,
          title: 'Daily briefing is ready',
          subtitle: briefing.length > 90 ? '${briefing.substring(0, 90)}…' : briefing,
          time: DateTime.now(),
        ),
      );
      _trimNotices();
    }
    _persist();
    notifyListeners();
  }

  Future<void> completeLesson(String id) async {
    completedIds.add(id);
    markPracticed();
    pushNotice(
      AiNotice(
        id: 'lesson_$id${DateTime.now().millisecondsSinceEpoch}',
        kind: IconKind.lesson,
        title: 'Lesson complete',
        subtitle: AiCoachService.instance.lessonFollowUp(id),
        time: DateTime.now(),
      ),
    );
  }

  void markPracticed() {
    final day = _dayKey(DateTime.now());
    if (lastActionDay == day) {
      _persist();
      notifyListeners();
      return;
    }
    if (lastActionDay != null) {
      final prev = DateTime.tryParse(lastActionDay!);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yKey = _dayKey(yesterday);
      if (prev != null && _dayKey(prev) == yKey) {
        streakDays += 1;
      } else {
        streakDays = 1;
      }
    } else {
      streakDays = 1;
    }
    lastActionDay = day;
    _persist();
    notifyListeners();
  }

  void pushNotice(AiNotice notice) {
    notices.removeWhere((n) => n.id == notice.id);
    notices.insert(0, notice);
    _trimNotices();
    _persist();
    notifyListeners();
  }

  void _trimNotices() {
    if (notices.length > 40) notices.removeRange(40, notices.length);
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _applyFromStore({bool force = false}) {
    final store = UserAccountStore.instance;
    if (!force && store.updatedAtIso == _appliedUpdatedAt) return;
    _loadFromMap(store.learning);
    _appliedUpdatedAt = store.updatedAtIso;
  }

  void _loadFromMap(Map<String, dynamic> map) {
    completedIds
      ..clear()
      ..addAll(((map['completed'] as List?) ?? []).map((e) => e.toString()));
    streakDays = (map['streak'] as num?)?.toInt() ?? 0;
    lastActionDay = map['lastActionDay'] as String?;
    briefing = map['briefing'] as String? ?? '';
    briefingDay = map['briefingDay'] as String?;
    notices
      ..clear()
      ..addAll(((map['notices'] as List?) ?? []).whereType<Map>().map(
            (e) => AiNotice.fromJson(Map<String, dynamic>.from(e)),
          ));
    _lastReviewTradeId = map['lastReviewTradeId'] as String?;
  }

  Map<String, dynamic> _toMap() => {
        'completed': completedIds.toList(),
        'streak': streakDays,
        'lastActionDay': lastActionDay,
        'briefing': briefing,
        'briefingDay': briefingDay,
        'lastReviewTradeId': _lastReviewTradeId,
        'notices': notices.map((n) => n.toJson()).toList(),
      };

  Future<void> _persist() async {
    if (_uid == null) return;
    UserAccountStore.instance.learning = _toMap();
    await UserAccountStore.instance.saveAll();
    _appliedUpdatedAt = UserAccountStore.instance.updatedAtIso;
  }
}
