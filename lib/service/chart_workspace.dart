import 'user_account_store.dart';

class ChartWorkspace {
  static const defaultDisplaySymbol = 'US100';
  static const defaultInterval = '15';

  static const displaySymbols = ['BTC/USDT', 'ETH/USDT', 'US100'];

  static const tvSymbols = {
    'BTC/USDT': 'BINANCE:BTCUSDT',
    'ETH/USDT': 'BINANCE:ETHUSDT',
    'US100': 'CAPITALCOM:US100',
  };

  static String tvSymbolOf(String display) =>
      tvSymbols[display] ?? tvSymbols[defaultDisplaySymbol]!;

  static String frameIdOf(String display) =>
      'trademaster_${tvSymbolOf(display).replaceAll(':', '_')}';

  static Future<String> loadInterval() async {
    final saved = UserAccountStore.instance.chartInterval;
    return saved.isEmpty ? defaultInterval : saved;
  }

  static Future<void> saveInterval(String interval) async {
    UserAccountStore.instance.chartInterval = interval;
    await UserAccountStore.instance.saveAll();
  }

  static Future<String> loadSymbol() async {
    final saved = UserAccountStore.instance.chartSymbol;
    if (tvSymbols.containsKey(saved)) return saved;
    return defaultDisplaySymbol;
  }

  static Future<void> saveSymbol(String display) async {
    UserAccountStore.instance.chartSymbol = display;
    await UserAccountStore.instance.saveAll();
  }

  /// Chart tab: full TradingView drawing + indicator toolbars.
  /// Trade tab: live price chart only (tools stay on Chart).
  static Uri embedUri({
    required String displaySymbol,
    String interval = defaultInterval,
    bool fullTools = true,
  }) {
    return Uri.https('www.tradingview.com', '/widgetembed/', {
      'frameElementId': frameIdOf(displaySymbol),
      'symbol': tvSymbolOf(displaySymbol),
      'interval': interval,
      'hidesidetoolbar': fullTools ? '0' : '1',
      'hidetoptoolbar': fullTools ? '0' : '1',
      'symboledit': fullTools ? '1' : '0',
      'saveimage': '1',
      'toolbarbg': '0d1117',
      'hideideas': fullTools ? '0' : '1',
      'theme': 'dark',
      'style': '1',
      'timezone': 'Etc/UTC',
      'withdateranges': fullTools ? '1' : '0',
      'hidevolume': '0',
      'details': fullTools ? '1' : '0',
      'hotlist': fullTools ? '1' : '0',
      'calendar': fullTools ? '1' : '0',
      'allow_symbol_change': fullTools ? '1' : '0',
      'hidelegend': '0',
      'support_host': 'https://www.tradingview.com',
      'locale': 'en',
    });
  }
}
