import 'package:flutter/material.dart';
import '../widgets/mobile_header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/chart_placeholder.dart';
import '../widgets/quick_trade_bar.dart';
import '../widgets/mobile_home.dart';
import '../widgets/mobile_portfolio.dart';
import '../widgets/mobile_settings.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  String mode = 'demo';
  String activeTab = 'home';
  String selectedSymbol = 'BTC/USDT';

  void setMode(String newMode) => setState(() => mode = newMode);
  void setActiveTab(String tab) => setState(() => activeTab = tab);

  Widget _buildContent() {
    switch (activeTab) {
      case 'home':
        return MobileHome(onTabChange: setActiveTab);
      case 'chart':
      case 'trade':
        return Column(
          children: [
            Expanded(child: ChartPlaceholder(symbol: selectedSymbol)),
            const QuickTradeBar(),
          ],
        );
      case 'portfolio':
        return const MobilePortfolio();
      case 'settings':
        return const MobileSettings();
      default:
        return MobileHome(onTabChange: setActiveTab);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildContent(),
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