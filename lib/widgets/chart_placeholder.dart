import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  // TODO: for production, don't hardcode the API key in the app -
  // proxy requests through your own backend instead.
  static const String _twelveDataApiKey = '2d445fc8b332409991193382e73b607b';

  late WebViewController controller;

  String selectedSymbol = 'BTC/USDT';
  double currentPrice = 0;

  WebSocketChannel? _binanceChannel;
  Timer? _twelveDataTimer;

  @override
  void initState() {
    super.initState();
    _loadChartFor(selectedSymbol);
    _startPriceFeed(selectedSymbol);
  }

  @override
  void dispose() {
    _binanceChannel?.sink.close();
    _twelveDataTimer?.cancel();
    super.dispose();
  }

  // ---------------- Live price feed ----------------

  void _startPriceFeed(String symbol) {
    // Tear down any existing feed first.
    _binanceChannel?.sink.close();
    _binanceChannel = null;
    _twelveDataTimer?.cancel();
    _twelveDataTimer = null;

    if (symbol == 'BTC/USDT') {
      _binanceChannel = WebSocketChannel.connect(
        Uri.parse('wss://stream.binance.com:9443/ws/btcusdt@trade'),
      );
      _binanceChannel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (!mounted) return;
        setState(() {
          currentPrice = double.parse(data['p']);
        });
      });
    } else {
      // US100 (Nasdaq 100). Twelve Data's free tier has no WebSocket, so we
      // poll the /price endpoint instead. Keep the interval conservative to
      // stay within the free-tier rate limit (8 requests/minute).
      _fetchTwelveDataPrice();
      _twelveDataTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _fetchTwelveDataPrice();
      });
    }
  }

  Future<void> _fetchTwelveDataPrice() async {
    try {
      final res = await http.get(Uri.parse(
        'https://api.twelvedata.com/price?symbol=NDX&apikey=$_twelveDataApiKey',
      ));
      final data = jsonDecode(res.body);
      if (data['price'] != null && mounted) {
        setState(() {
          currentPrice = double.parse(data['price']);
        });
      }
    } catch (e) {
      // Ignore transient network errors; the next poll will retry.
    }
  }

  // ---------------- Symbol switching ----------------

  void _switchSymbol(String symbol) {
    if (symbol == selectedSymbol) return;
    setState(() {
      selectedSymbol = symbol;
      currentPrice = 0;
    });
    _loadChartFor(symbol);
    _startPriceFeed(symbol);
  }

  // ---------------- Chart (WebView + lightweight-charts) ----------------

  void _loadChartFor(String symbol) {
    final fetchScript =
    symbol == 'BTC/USDT' ? _binanceFetchScript() : _twelveDataFetchScript();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString("""
<!DOCTYPE html>
<html>
<head>
<script src="https://unpkg.com/lightweight-charts/dist/lightweight-charts.standalone.production.js"></script>

<style>
body{
margin:0;
background:#0d1117;
}

#chart{
width:100vw;
height:100vh;
}
</style>
</head>

<body>

<div id="chart"></div>

<script>

const chart = LightweightCharts.createChart(
document.getElementById('chart'),
{
layout:{
background:{
color:'#0d1117'
},
textColor:'white'
},

grid:{
vertLines:{
color:'rgba(255,255,255,0.05)'
},
horzLines:{
color:'rgba(255,255,255,0.05)'
}
},

width:window.innerWidth,
height:window.innerHeight,
});

const candleSeries = chart.addCandlestickSeries();

$fetchScript

</script>

</body>
</html>
""");
  }

  String _binanceFetchScript() {
    return """
fetch('https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m&limit=100')
.then(res => res.json())
.then(data => {

const candles = data.map(item => ({
time: item[0] / 1000,
open: parseFloat(item[1]),
high: parseFloat(item[2]),
low: parseFloat(item[3]),
close: parseFloat(item[4]),
}));

candleSeries.setData(candles);

});
""";
  }

  String _twelveDataFetchScript() {
    return """
fetch('https://api.twelvedata.com/time_series?symbol=NDX&interval=1min&outputsize=100&apikey=$_twelveDataApiKey')
.then(res => res.json())
.then(data => {

if (!data.values) return;

const candles = data.values.map(item => ({
time: Math.floor(new Date(item.datetime + ' UTC').getTime() / 1000),
open: parseFloat(item.open),
high: parseFloat(item.high),
low: parseFloat(item.low),
close: parseFloat(item.close),
})).reverse();

candleSeries.setData(candles);

});
""";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0d1117),

      body: Column(
        children: [
          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedSymbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "\$${currentPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _symbolButton('BTC/USDT')),
                    const SizedBox(width: 8),
                    Expanded(child: _symbolButton('US100')),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: WebViewWidget(
              controller: controller,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                    ),
                    onPressed: () {
                      print("BUY at $currentPrice");
                    },
                    child: const Text(
                      "BUY / LONG",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                    ),
                    onPressed: () {
                      print("SELL at $currentPrice");
                    },
                    child: const Text(
                      "SELL / SHORT",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _symbolButton(String symbol) {
    final isActive = symbol == selectedSymbol;
    return GestureDetector(
      onTap: () => _switchSymbol(symbol),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}