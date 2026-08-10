import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late WebViewController controller;

  double btcPrice = 0;

  final channel = WebSocketChannel.connect(
    Uri.parse(
      'wss://stream.binance.com:9443/ws/btcusdt@trade',
    ),
  );

  @override
  void initState() {
    super.initState();

    initChart();

    listenPrice();
  }

  void listenPrice() {
    channel.stream.listen((message) {
      final data = jsonDecode(message);

      setState(() {
        btcPrice = double.parse(data['p']);
      });
    });
  }

  void initChart() {
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

</script>

</body>
</html>
""");
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
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [

                const Text(
                  "BTC/USDT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "\$${btcPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                    ),
                    onPressed: () {

                      print(
                        "BUY at $btcPrice",
                      );
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
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                    ),
                    onPressed: () {

                      print(
                        "SELL at $btcPrice",
                      );
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
}