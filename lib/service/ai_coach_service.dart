import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'demo_trade_service.dart';
import 'us100_quote_service.dart';

class RiskVerdict {
  final bool shouldWarn;
  final String title;
  final List<String> points;

  const RiskVerdict({
    required this.shouldWarn,
    required this.title,
    required this.points,
  });
}

/// Context-aware coach for the demo account.
/// Educational only — never a buy/sell signal.
class AiCoachService {
  AiCoachService._();
  static final AiCoachService instance = AiCoachService._();

  String accountContext() {
    final demo = DemoTradeService.instance;
    final q = Us100QuoteService.instance;
    final px = q.hasQuote ? q.last.toStringAsFixed(2) : 'n/a';
    final open = demo.positions
        .map((p) {
          final pnl = q.hasQuote
              ? p.pnl(q.bid, q.ask).toStringAsFixed(2)
              : '—';
          return '${p.side} ${p.lots.toStringAsFixed(2)} ${p.symbol} @ ${p.openPrice.toStringAsFixed(2)} SL=${p.sl?.toStringAsFixed(2) ?? 'none'} TP=${p.tp?.toStringAsFixed(2) ?? 'none'} P/L=$pnl';
        })
        .join('\n');
    final recent = demo.trades.take(8).map((t) {
      final sign = t.pnl >= 0 ? '+' : '';
      return '${t.side} ${t.lots.toStringAsFixed(2)} ${t.symbol} ${sign}${t.pnl.toStringAsFixed(2)} (${t.closeReason})';
    }).join('\n');
    final wins = demo.trades.where((t) => t.pnl > 0.005).length;
    return [
      'Demo balance: \$${demo.balance.toStringAsFixed(2)}',
      'US100 last: $px  bid=${q.bid.toStringAsFixed(2)} ask=${q.ask.toStringAsFixed(2)}',
      'Open positions (${demo.positions.length}): ${open.isEmpty ? 'none' : '\n$open'}',
      'Closed trades: ${demo.trades.length}, wins: $wins',
      'Recent closes:\n${recent.isEmpty ? 'none yet' : recent}',
    ].join('\n');
  }

  String dailyBriefing() {
    final demo = DemoTradeService.instance;
    final q = Us100QuoteService.instance;
    final parts = <String>[];
    if (q.hasQuote) {
      parts.add(
        'US100 is around ${q.last.toStringAsFixed(2)} (spread ${ (q.ask - q.bid).toStringAsFixed(2) }).',
      );
    } else {
      parts.add('Waiting on a live US100 quote — open the Chart or Trade tab to attach the feed.');
    }
    if (demo.positions.isEmpty) {
      parts.add('No open demo trades. A small size with a stop is a cleaner practice than guessing direction.');
    } else {
      final qOk = q.hasQuote;
      double floatPnl = 0;
      var missingSl = 0;
      for (final p in demo.positions) {
        if (qOk) floatPnl += p.pnl(q.bid, q.ask);
        if (p.sl == null) missingSl++;
      }
      final sign = floatPnl >= 0 ? '+' : '';
      parts.add(
        'You have ${demo.positions.length} open trade${demo.positions.length == 1 ? '' : 's'} (${sign}\$${floatPnl.toStringAsFixed(2)} floating).',
      );
      if (missingSl > 0) {
        parts.add('$missingSl of them have no stop loss — that is the first thing to fix.');
      }
    }
    if (demo.trades.isNotEmpty) {
      final today = DateTime.now();
      final todays = demo.trades.where((t) =>
          t.closeTime.year == today.year &&
          t.closeTime.month == today.month &&
          t.closeTime.day == today.day);
      final dayPnl = todays.fold<double>(0, (a, t) => a + t.pnl);
      if (todays.isNotEmpty) {
        parts.add(
          'Today you closed ${todays.length} trade${todays.length == 1 ? '' : 's'} for ${dayPnl >= 0 ? '+' : ''}\$${dayPnl.toStringAsFixed(2)}.',
        );
      } else {
        parts.add('No closes yet today. Review your last trade before opening another.');
      }
    } else {
      parts.add('Take the first demo trade only after you set lots, SL, and a reason for the idea.');
    }
    parts.add('Educational practice — not financial advice.');
    return parts.join(' ');
  }

  String reviewTrade(DemoTrade t) {
    final holdMin = max(0, t.closeTime.difference(t.time).inMinutes);
    final win = t.pnl > 0.005;
    final loss = t.pnl < -0.005;
    final bits = <String>[];
    if (win) {
      bits.add('Winner: ${t.side} ${t.lots.toStringAsFixed(2)} lot ${t.symbol} made \$${t.pnl.toStringAsFixed(2)}.');
    } else if (loss) {
      bits.add('Loser: ${t.side} ${t.lots.toStringAsFixed(2)} lot ${t.symbol} cost \$${t.pnl.abs().toStringAsFixed(2)}.');
    } else {
      bits.add('Scratch: almost flat on ${t.symbol}.');
    }
    if (t.sl == null) {
      bits.add(win
          ? 'It worked without a stop — that luck should not become a habit.'
          : 'No stop was set, so the loss size was uncontrolled.');
    } else if (t.closeReason == 'sl') {
      bits.add('The stop did its job. That is process, not failure.');
    }
    if (t.tp != null && t.closeReason == 'tp') {
      bits.add('Take-profit filled as planned.');
    }
    if (holdMin < 1 && loss) {
      bits.add('Closed in under a minute — that often means reacting, not executing a plan.');
    } else if (holdMin > 240 && win) {
      bits.add('You let the idea work for ${holdMin ~/ 60}h. Patience helped.');
    }
    final riskUnits = t.lots * DemoPosition.pointValue;
    if (t.lots >= 1) {
      bits.add('Size (${t.lots.toStringAsFixed(2)} lots) is large for a \$10k-style demo. Scale down while learning.');
    } else if (riskUnits > 0 && t.pnl.abs() > 200) {
      bits.add('P/L swing was large vs a practice account — next time cut lots or tighten the stop.');
    }
    bits.add('Ask the coach: what would you change on the next ${t.symbol} trade?');
    return bits.join(' ');
  }

  String explainChart(String symbol) {
    final q = Us100QuoteService.instance;
    final demo = DemoTradeService.instance;
    final bits = <String>[];
    bits.add('$symbol — this is a practice chart, not a buy/sell call.');
    if (q.hasQuote) {
      bits.add(
        'Last ${q.last.toStringAsFixed(2)}, bid ${q.bid.toStringAsFixed(2)}, ask ${q.ask.toStringAsFixed(2)}. Spread ${(q.ask - q.bid).toStringAsFixed(2)} is the cost of getting in and out.',
      );
      bits.add(q.live
          ? 'The quote is live. Watch structure (higher highs / lower lows) before clicking Buy or Sell.'
          : 'The quote looks delayed — wait for a fresh tick before judging a breakout.');
    } else {
      bits.add('No last price yet. Stay on this tab a few seconds so the chart feed can attach.');
    }
    final onSymbol = demo.positions.where((p) => p.symbol == symbol || symbol.contains('US100')).toList();
    if (onSymbol.isNotEmpty) {
      bits.add(
        'You already have ${onSymbol.length} open demo position${onSymbol.length == 1 ? '' : 's'} on this market. Adding more is stacking risk, not “more analysis”.',
      );
    }
    final last = demo.trades.where((t) => t.symbol == 'US100' || symbol.contains(t.symbol)).toList();
    if (last.isNotEmpty) {
      bits.add('Last close: ${last.first.side} for ${last.first.pnl >= 0 ? '+' : ''}\$${last.first.pnl.toStringAsFixed(2)}. Do not revenge-trade the next candle.');
    }
    bits.add('Mark a level, define invalidation (SL), then size lots so a stop-out is a lesson — not a blown demo.');
    return bits.join(' ');
  }

  RiskVerdict assessOrder({
    required String side,
    required double lots,
    required double? sl,
    required double? tp,
  }) {
    final demo = DemoTradeService.instance;
    final q = Us100QuoteService.instance;
    final points = <String>[];
    final margin = lots * 100;
    if (lots >= 1) {
      points.add('Volume ${lots.toStringAsFixed(2)} lots is aggressive on a \$${demo.balance.toStringAsFixed(0)} demo.');
    }
    if (margin > demo.balance * 0.25) {
      points.add(
        'Required margin \$${margin.toStringAsFixed(0)} is more than 25% of balance.',
      );
    }
    final sameWay = demo.positions.where((p) => p.side == side).length;
    if (sameWay >= 2) {
      points.add('You already have $sameWay open $side position(s). Stacking the same bet multiplies one mistake.');
    }
    if (demo.positions.length >= 4) {
      points.add('Four+ open trades is a lot for practice. Manage what is open first.');
    }
    if (q.hasQuote && sl != null && sl > 0) {
      final fill = side == 'BUY' ? q.ask : q.bid;
      final slPx = DemoTradeService.resolveLevel(
            side: side,
            isStopLoss: true,
            fill: fill,
            raw: sl,
          ) ??
          sl;
      final dist = (fill - slPx).abs();
      final dollarRisk = dist * lots * DemoPosition.pointValue;
      if (dollarRisk > demo.balance * 0.05) {
        points.add(
          'Stop distance implies ~\$${dollarRisk.toStringAsFixed(0)} risk — over 5% of the demo. Cut lots or tighten the stop.',
        );
      }
    }
    if (points.isEmpty) {
      return const RiskVerdict(
        shouldWarn: false,
        title: 'Risk looks reasonable',
        points: ['Size, stop, and open exposure are inside a practice-friendly range.'],
      );
    }
    return RiskVerdict(
      shouldWarn: true,
      title: 'Coach pause before $side',
      points: points,
    );
  }

  /// Free cloud model (Pollinations, no API key). Falls back to on-device coach.
  Future<String> ask(String raw, {List<String> prior = const []}) async {
    final local = reply(raw);
    if (_isPriceCall(raw.toLowerCase())) return local;
    try {
      final remote = await _freeModel(raw, prior).timeout(const Duration(seconds: 22));
      if (remote != null && remote.trim().length > 8) return remote.trim();
    } catch (_) {}
    return local;
  }

  Future<String?> _freeModel(String userText, List<String> prior) async {
    final sys =
        'You are Virtual Trading AI, a friendly demo-trading coach. '
        'Be natural, short, and useful. Never give buy/sell signals or price predictions. '
        'Say this is educational, not financial advice when talking about markets.\n\n'
        'Live demo snapshot:\n${accountContext()}';
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': sys},
    ];
    for (final line in prior.take(8)) {
      messages.add({'role': 'user', 'content': line});
    }
    messages.add({'role': 'user', 'content': userText});

    final payload = jsonEncode({
      'model': 'openai',
      'messages': messages,
    });

    final post = await http
        .post(
          Uri.parse('https://text.pollinations.ai/openai'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/plain',
          },
          body: payload,
        )
        .timeout(const Duration(seconds: 18));
    final parsed = _parseModelBody(post.body);
    if (post.statusCode == 200 && parsed != null) return parsed;

    final q = Uri.encodeComponent(
      '$sys\n\nUser: $userText\nReply in 2-6 short sentences.',
    );
    final get = await http
        .get(Uri.parse('https://text.pollinations.ai/$q'))
        .timeout(const Duration(seconds: 18));
    if (get.statusCode == 200 && get.body.trim().length > 8) {
      return get.body.trim();
    }
    return parsed;
  }

  String? _parseModelBody(String body) {
    final t = body.trim();
    if (t.isEmpty) return null;
    try {
      final json = jsonDecode(t);
      if (json is Map) {
        final choices = json['choices'];
        if (choices is List && choices.isNotEmpty) {
          final msg = (choices.first as Map)['message'];
          if (msg is Map) {
            final c = msg['content']?.toString();
            if (c != null && c.trim().isNotEmpty) return c;
          }
        }
        final inner = json['text']?.toString() ?? json['response']?.toString();
        if (inner != null && inner.trim().isNotEmpty) return inner;
      }
    } catch (_) {
      if (!t.startsWith('{') && t.length > 8) return t;
    }
    return null;
  }

  String reply(String raw) {
    final q = raw.trim();
    if (q.isEmpty) {
      return 'Ask about your open trades, risk, the last close, or the US100 chart. I only coach this demo — I do not predict prices.';
    }
    final lower = q.toLowerCase();
    if (_isPriceCall(lower)) {
      return 'I will not tell you to buy or sell the next candle. Use the Chart explainer for structure, the risk check before an order, and a post-trade review after you close. ${dailyBriefing()}';
    }
    if (lower.contains('brief') || lower.contains('today') || lower.contains('morning')) {
      return dailyBriefing();
    }
    if (lower.contains('chart') || lower.contains('explain') || lower.contains('level')) {
      return explainChart('US100');
    }
    if (lower.contains('risk') || lower.contains('lot') || lower.contains('size') || lower.contains('stop')) {
      return _riskLesson();
    }
    if (lower.contains('review') || lower.contains('last trade') || lower.contains('closed')) {
      final trades = DemoTradeService.instance.trades;
      if (trades.isEmpty) return 'No closed trades yet. After you close one, I will write a review on it in Portfolio.';
      return trades.first.review ?? reviewTrade(trades.first);
    }
    if (lower.contains('open') || lower.contains('position') || lower.contains('floating')) {
      return _openBook();
    }
    if (lower.contains('lesson') ||
        lower.contains('learn') ||
        lower.contains('quiz') ||
        lower.contains('teach') ||
        lower.contains('smc') ||
        lower.contains('ict') ||
        lower.contains('fvg')) {
      return 'Tap Teach Me Trading (the green school button). It opens a list of ICT/SMC topics — FVG, IFVG, BPR, order block, breaker, Silver Bullet, Unicorn, Market Maker model, Turtle Soup, and more. Each topic is its own file with a US100 example chart. Home → Learning Path is still the short demo-account quizzes.';
    }
    if (lower.contains('help') || lower.contains('what can')) {
      return 'I can: 1) daily briefing, 2) explain the US100 chart, 3) warn before oversized orders, 4) review closed demo trades, 5) walk the learning path. I do not give financial advice.';
    }
    return '${_openBook()}\n\n${dailyBriefing()}';
  }

  bool _isPriceCall(String lower) {
    return lower.contains('buy now') ||
        lower.contains('sell now') ||
        lower.contains('will it go') ||
        lower.contains('predict') ||
        lower.contains('signal') ||
        lower.contains('guaranteed') ||
        RegExp(r'\b(buy|sell)\s+(us100|nasdaq|btc)\b').hasMatch(lower);
  }

  String _openBook() {
    final demo = DemoTradeService.instance;
    final q = Us100QuoteService.instance;
    if (demo.positions.isEmpty) {
      return 'No open positions. Balance \$${demo.balance.toStringAsFixed(2)}. When you enter, set lots so a stop-out is affordable, then define SL before you tap Buy or Sell.';
    }
    final lines = demo.positions.map((p) {
      final pnl = q.hasQuote ? p.pnl(q.bid, q.ask) : 0.0;
      final sl = p.sl == null ? 'no SL' : 'SL ${p.sl!.toStringAsFixed(2)}';
      return '• ${p.side} ${p.lots.toStringAsFixed(2)} ${p.symbol} @ ${p.openPrice.toStringAsFixed(2)}, $sl, floating ${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}';
    });
    return 'Open book:\n${lines.join('\n')}\nManage these before adding a new idea.';
  }

  String _riskLesson() {
    final demo = DemoTradeService.instance;
    return 'On this demo, margin is about \$100 per lot. Balance is \$${demo.balance.toStringAsFixed(2)}. '
        'A starter rule: risk a small slice of the account per idea (about 1–2%), always set SL, and avoid stacking three trades the same way. '
        'The Trade tab will pause you if size or missing stops look unsafe.';
  }

  String lessonFollowUp(String lessonId) {
    switch (lessonId) {
      case 'demo':
        return 'Next: open Trade, use 0.01–0.04 lots, and treat every fill as practice — not P/L bragging.';
      case 'spread':
        return 'Next: watch bid vs ask on the Trade bar. A tiny scalp can be just the spread.';
      case 'lots':
        return 'Next: place a 0.02 lot demo with a stop. If that feels boring, the size is probably right.';
      case 'stops':
        return 'Next: enter US100 with both SL and TP filled in. Close it only if the plan is done.';
      case 'overtrade':
        return 'Next: one idea today. If it is open, do not add a second “just in case”.';
      case 'review':
        return 'Next: close a small trade, then read the AI review on Portfolio. Write one sentence you would change.';
      default:
        return 'Continue on Learning Path, then take the suggested demo trade.';
    }
  }
}
