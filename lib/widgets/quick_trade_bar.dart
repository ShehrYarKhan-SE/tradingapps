import 'package:flutter/material.dart';

import '../service/demo_trade_service.dart';
import '../service/us100_quote_service.dart';
import '../service/ai_coach_service.dart';
import '../theme_controller.dart';

/// MT5-style one-click bar: SELL | lot size | BUY
class QuickTradeBar extends StatefulWidget {
  const QuickTradeBar({super.key});

  @override
  State<QuickTradeBar> createState() => _QuickTradeBarState();
}

class _QuickTradeBarState extends State<QuickTradeBar> {
  double _lots = 0.04;
  final _quotes = Us100QuoteService.instance;
  final _demo = DemoTradeService.instance;

  static const _sell = Color(0xFFE53935);
  static const _buy = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    _quotes.attach();
    _quotes.addListener(_tick);
    _demo.init();
  }

  @override
  void dispose() {
    _quotes.removeListener(_tick);
    _quotes.detach();
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _nudgeLots(double delta) {
    setState(() {
      _lots = (_lots + delta).clamp(0.01, 50.0);
      _lots = double.parse(_lots.toStringAsFixed(2));
    });
  }

  Future<void> _submit(String side) async {
    await _quotes.prepareFill();
    if (!_quotes.hasQuote) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF7F1D1D),
          content: Text('Waiting for live price. Try again in a moment.'),
        ),
      );
      return;
    }
    final fill = side == 'BUY' ? _quotes.ask : _quotes.bid;
    final risk = AiCoachService.instance.assessOrder(
      side: side,
      lots: _lots,
      sl: null,
      tp: null,
    );
    if (risk.shouldWarn) {
      final go = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.of(context).sheet,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk.title, style: TextStyle(color: AppColors.of(context).text, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...risk.points.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ', style: TextStyle(color: Color(0xFFFBBF24))),
                        Expanded(child: Text(p, style: const TextStyle(color: Colors.white70, height: 1.35))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Place anyway'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
      if (go != true) return;
      if (!mounted) return;
    }
    final err = _demo.openMarket(
      side: side,
      lots: _lots,
      bid: _quotes.bid,
      ask: _quotes.ask,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: err == null
            ? (side == 'BUY' ? const Color(0xFF1565C0) : const Color(0xFFB71C1C))
            : const Color(0xFF7F1D1D),
        content: Text(
          err ??
              'Demo ${side == 'BUY' ? 'Buy' : 'Sell'} $_lots US100 @ ${fill.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
            children: [
              Expanded(child: _sideButton('SELL', _quotes.bid, _sell, () => _submit('SELL'))),
              const SizedBox(width: 6),
              _lotBox(),
              const SizedBox(width: 6),
              Expanded(child: _sideButton('BUY', _quotes.ask, _buy, () => _submit('BUY'))),
            ],
          ),
    );
  }

  Widget _sideButton(String label, double price, Color color, VoidCallback onTap) {
    final text = price > 0 ? price.toStringAsFixed(2) : '--.--';
    final main = text.substring(0, text.length - 2);
    final frac = text.substring(text.length - 2);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  children: [
                    TextSpan(text: main, style: const TextStyle(fontSize: 18)),
                    TextSpan(text: frac, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lotBox() {
    return Container(
      width: 78,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFD0D0D0)),
      ),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _nudgeLots(0.01),
              child: const Center(
                child: Icon(Icons.arrow_drop_up, size: 22, color: Color(0xFF616161)),
              ),
            ),
          ),
          Text(
            _lots.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _nudgeLots(-0.01),
              child: const Center(
                child: Icon(Icons.arrow_drop_down, size: 22, color: Color(0xFF616161)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
