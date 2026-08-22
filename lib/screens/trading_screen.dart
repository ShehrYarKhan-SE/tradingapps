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

  @override
  void initState() {
    super.initState();
    DemoTradeService.instance.init();
    ChartWorkspace.loadSymbol().then((s) {
      if (mounted) setState(() => selectedSymbol = s);
    });
  }

  void setMode(String newMode) => setState(() => mode = newMode);
  void setActiveTab(String tab) => setState(() => activeTab = tab);

  void openChart(String symbol) {
    ChartWorkspace.saveSymbol(symbol);
    setState(() {
      selectedSymbol = symbol;
      activeTab = 'chart';
    });
  }

  Widget _chartSymbolBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF121212),
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
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          const Text(
            'Live · TradingView tools',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _keepAlive({required bool visible, required Widget child}) {
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showChart = activeTab == 'chart' || activeTab == 'trade';
    final isTrade = activeTab == 'trade';

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
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
                  _keepAlive(
                    visible: activeTab == 'home',
                    child: MobileHome(
                      onTabChange: setActiveTab,
                      onOpenChart: openChart,
                    ),
                  ),
                  _keepAlive(
                    visible: activeTab == 'portfolio',
                    child: const MobilePortfolio(),
                  ),
                  _keepAlive(
                    visible: activeTab == 'settings',
                    child: const MobileSettings(),
                  ),
                  _keepAlive(
                    visible: showChart,
                    child: Column(
                      children: [
                        if (isTrade) const QuickTradeBar(),
                        if (isTrade) const Us100QuoteStrip(),
                        if (!isTrade) _chartSymbolBar(),
                        Expanded(
                          child: ChartScreen(
                            key: _chartKey,
                            visible: showChart,
                            compact: isTrade,
                            displaySymbol: selectedSymbol,
                          ),
                        ),
                        if (isTrade) const Us100PositionsPanel(),
                      ],
                    ),
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
