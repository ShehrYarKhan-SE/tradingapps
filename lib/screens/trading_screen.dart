import 'package:flutter/material.dart';
import '../widgets/mobile_header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/chart_placeholder.dart';
import '../widgets/us100_trade_tab.dart';
import '../widgets/quick_trade_bar.dart';
import '../widgets/mobile_home.dart';
import '../widgets/mobile_portfolio.dart';
import '../widgets/mobile_settings.dart';
import '../service/demo_trade_service.dart';
import '../service/chart_workspace.dart';
import '../service/us100_quote_service.dart';
import '../service/user_account_store.dart';
import '../service/ai_coach_service.dart';
import '../service/ai_learning_store.dart';
import '../theme_controller.dart';
import 'ai_coach_screen.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  String mode = 'demo';
  String activeTab = 'home';
  String selectedSymbol = 'US100';
  final _chartKey = GlobalKey();
  bool _booted = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await UserAccountStore.instance.bindToCurrentUser();
    await DemoTradeService.instance.init();
    await AiLearningStore.instance.bind();
    Us100QuoteService.instance.attach();
    final s = await ChartWorkspace.loadSymbol();
    if (!mounted) return;
    setState(() {
      selectedSymbol = s;
      _booted = true;
    });
  }

  @override
  void dispose() {
    Us100QuoteService.instance.detach();
    super.dispose();
  }

  void setMode(String newMode) => setState(() => mode = newMode);
  void setActiveTab(String tab) => setState(() => activeTab = tab);

  void _explainChart() {
    final text = AiCoachService.instance.explainChart(selectedSymbol);
    final colors = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chart explainer',
                style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(text, style: TextStyle(color: colors.muted, height: 1.4)),
              const SizedBox(height: 8),
              Text(
                'Educational only — not a buy or sell signal.',
                style: TextStyle(color: colors.muted.withValues(alpha: 0.8), fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  void openChart(String symbol) {
    ChartWorkspace.saveSymbol(symbol);
    setState(() {
      selectedSymbol = symbol;
      activeTab = 'chart';
    });
  }

  Widget _chartSymbolBar() {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      color: colors.header,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          ...ChartWorkspace.displaySymbols.map((s) {
            final selected = s == selectedSymbol;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => openChart(s),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : colors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : colors.border,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: selected ? Colors.white : colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (activeTab == 'chart')
            GestureDetector(
              onTap: _explainChart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.45)),
                ),
                child: const Text(
                  'Explain',
                  style: TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Text(
              'Live · drawings · indicators',
              style: TextStyle(color: colors.muted, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _chartPane({required bool isTrade}) {
    final isChart = activeTab == 'chart';
    return Column(
      children: [
        if (isTrade) const QuickTradeBar(),
        if (isTrade) const Us100QuoteStrip(),
        if (isChart) _chartSymbolBar(),
        Expanded(
          child: ChartScreen(
            key: _chartKey,
            visible: activeTab == 'chart' || activeTab == 'trade',
            compact: isTrade,
            displaySymbol: selectedSymbol,
          ),
        ),
        if (isTrade) const Us100PositionsPanel(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (!_booted) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }
    final showChart = activeTab == 'chart' || activeTab == 'trade';
    final isTrade = activeTab == 'trade';

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            MobileHeader(
              mode: mode,
              onModeChange: setMode,
              symbol: selectedSymbol,
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    ignoring: !showChart,
                    child: _chartPane(isTrade: isTrade),
                  ),
                  if (activeTab == 'home')
                    ColoredBox(
                      color: colors.scaffold,
                      child: MobileHome(
                        onTabChange: setActiveTab,
                        onOpenChart: openChart,
                      ),
                    ),
                  Offstage(
                    offstage: activeTab != 'coach',
                    child: TickerMode(
                      enabled: activeTab == 'coach',
                      child: const AiCoachScreen(embedded: true),
                    ),
                  ),
                  if (activeTab == 'portfolio')
                    ColoredBox(
                      color: colors.scaffold,
                      child: const MobilePortfolio(),
                    ),
                  if (activeTab == 'settings')
                    ColoredBox(
                      color: colors.scaffold,
                      child: const MobileSettings(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        activeTab: activeTab,
        onTabChange: setActiveTab,
      ),
    );
  }
}