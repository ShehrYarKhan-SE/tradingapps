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
    final fallback = UserAccountStore.instance.defaultMarket;
    if (tvSymbols.containsKey(fallback)) return fallback;
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
    final params = <String, String>{
      'frameElementId': frameIdOf(displaySymbol),
      'symbol': tvSymbolOf(displaySymbol),
      'interval': interval,
      'hidesidetoolbar': '1',
      'hidetoptoolbar': '0',
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
      'hotlist': '0',
      'calendar': '0',
      'allow_symbol_change': fullTools ? '1' : '0',
      'hidelegend': '0',
      'support_host': 'https://www.tradingview.com',
      'locale': 'en',
    };
    if (fullTools) {
      params['studies'] = 'MASimple@tv-basicstudies';
    }
    return Uri.https('www.tradingview.com', '/widgetembed/', params);
  }

  static String widgetHtml({
    required String displaySymbol,
    String interval = defaultInterval,
    bool fullTools = true,
  }) {
    final symbol = tvSymbolOf(displaySymbol);
    final hideSide = fullTools ? 'false' : 'true';
    final allowChange = fullTools ? 'true' : 'false';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
html, body, #tv_chart { margin:0; padding:0; height:100%; width:100%; background:#0d1117; }
</style>
</head>
<body>
<div id="tv_chart"></div>
<script src="https://s3.tradingview.com/tv.js"></script>
<script>
new TradingView.widget({
  autosize: true,
  symbol: "$symbol",
  interval: "$interval",
  timezone: "Etc/UTC",
  theme: "dark",
  style: "1",
  locale: "en",
  toolbar_bg: "#0d1117",
  enable_publishing: false,
  hide_top_toolbar: false,
  hide_legend: false,
  hide_side_toolbar: $hideSide,
  allow_symbol_change: $allowChange,
  withdateranges: $fullTools,
  details: $fullTools,
  hotlist: $fullTools,
  calendar: false,
  hide_volume: false,
  save_image: true,
  container_id: "tv_chart"
});
</script>
</body>
</html>
''';
  }
}
