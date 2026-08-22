import 'package:flutter/material.dart';

import '../service/demo_trade_service.dart';
import '../service/us100_quote_service.dart';

class Us100QuoteStrip extends StatelessWidget {
  const Us100QuoteStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = DemoTradeService.instance;
    final quotes = Us100QuoteService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([demo, quotes]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              const Text(
                'US100  M15',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CFD · Nasdaq 100  ·  Demo \$${demo.balance.toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
              Text(
                quotes.live ? 'Live' : 'Quote delayed',
                style: TextStyle(
                  color: quotes.live
                      ? const Color(0xFF26A69A)
                      : Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Us100PositionsPanel extends StatefulWidget {
  const Us100PositionsPanel({super.key});

  @override
  State<Us100PositionsPanel> createState() => _Us100PositionsPanelState();
}

class _Us100PositionsPanelState extends State<Us100PositionsPanel> {
  final _demo = DemoTradeService.instance;
  final _quotes = Us100QuoteService.instance;

  @override
  void initState() {
    super.initState();
    _demo.init();
    _quotes.attach();
    _demo.addListener(_tick);
    _quotes.addListener(_tick);
  }

  @override
  void dispose() {
    _demo.removeListener(_tick);
    _quotes.removeListener(_tick);
    _quotes.detach();
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final open = _demo.positions;
    final closed = _demo.trades.take(8).toList();
    return Container(
      height: 168,
      color: const Color(0xFF121212),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Text(
              'Trade  ·  Open positions are stored on this device',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Expanded(
            child: open.isEmpty && closed.isEmpty
                ? const Center(
                    child: Text(
                      'No demo positions. Tap SELL or BUY to trade US100.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      ...open.map(_openRow),
                      if (open.isNotEmpty && closed.isNotEmpty)
                        const Divider(color: Colors.white12, height: 8),
                      ...closed.map(_closedRow),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _openRow(DemoPosition p) {
    final pnl = p.pnl(_quotes.bid, _quotes.ask);
    final up = pnl >= 0;
    final color =
        p.side == 'BUY' ? const Color(0xFF1E88E5) : const Color(0xFFE53935);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        '${p.symbol}  ${p.side}  ${p.lots.toStringAsFixed(2)}',
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Open ${p.openPrice.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${up ? '+' : ''}${pnl.toStringAsFixed(2)}',
            style: TextStyle(
              color: up ? const Color(0xFF26A69A) : const Color(0xFFE53935),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () =>
                _demo.closePosition(p.id, _quotes.bid, _quotes.ask),
            style: TextButton.styleFrom(
              foregroundColor: color,
              minimumSize: const Size(48, 32),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _closedRow(DemoTrade t) {
    final up = t.pnl >= 0;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        '${t.symbol}  ${t.side}  ${t.lots.toStringAsFixed(2)}  closed',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      subtitle: Text(
        '${t.openPrice.toStringAsFixed(2)} → ${t.closePrice.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      trailing: Text(
        '${up ? '+' : ''}${t.pnl.toStringAsFixed(2)}',
        style: TextStyle(
          color: up ? const Color(0xFF26A69A) : const Color(0xFFE53935),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
