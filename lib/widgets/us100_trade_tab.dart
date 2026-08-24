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
                  'CFD · Nasdaq 100  ·  ${quotes.last > 0 ? quotes.last.toStringAsFixed(2) : '—'}  ·  Demo \$${demo.balance.toStringAsFixed(2)}',
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
              'Trade  ·  tap a position to close',
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
        'Open ${p.openPrice.toStringAsFixed(2)}'
        '${p.sl != null ? '  SL ${p.sl!.toStringAsFixed(2)}' : ''}'
        '${p.tp != null ? '  TP ${p.tp!.toStringAsFixed(2)}' : ''}',
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
      onTap: () => _editLevels(p),
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
    final reason = t.closeReason == 'sl'
        ? 'SL'
        : t.closeReason == 'tp'
            ? 'TP'
            : 'closed';
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        '${t.symbol}  ${t.side}  ${t.lots.toStringAsFixed(2)}  $reason',
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

  Future<void> _editLevels(DemoPosition p) async {
    final slCtrl = TextEditingController(text: p.sl?.toStringAsFixed(2) ?? '');
    final tpCtrl = TextEditingController(text: p.tp?.toStringAsFixed(2) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Stop Loss / Take Profit',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Open ${p.openPrice.toStringAsFixed(2)}  ${p.side}\n'
              'BUY: SL below / TP above. SELL: SL above / TP below.\n'
              'Enter a price (e.g. 29050) or points (e.g. 40).',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Stop Loss',
                labelStyle: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
            TextField(
              controller: tpCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Take Profit',
                labelStyle: TextStyle(color: Color(0xFF22C55E)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final sl = double.tryParse(slCtrl.text.trim());
      final tp = double.tryParse(tpCtrl.text.trim());
      final err = _demo.updateLevels(
        p.id,
        sl: sl,
        tp: tp,
        clearSl: slCtrl.text.trim().isEmpty,
        clearTp: tpCtrl.text.trim().isEmpty,
      );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      } else {
        _demo.applyStops(_quotes.bid, _quotes.ask);
      }
    }
    slCtrl.dispose();
    tpCtrl.dispose();
  }
}
