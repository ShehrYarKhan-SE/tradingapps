import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late WebViewController controller;
  double us100Price = 0;
  bool isReady = false;

  // Current selected interval (TradingView interval codes)
  String selectedInterval = "1";

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // Safety net: force the page to re-check its size in case the
            // WebView's final bounds settled after the chart already loaded.
            Future.delayed(const Duration(milliseconds: 300), () {
              controller.runJavaScript(
                "window.dispatchEvent(new Event('resize'));",
              );
            });
          },
        ),
      );

    // Wait until Flutter has finished laying out this widget at its real,
    // final size before loading the chart, otherwise TradingView's
    // autosize calculates against a too-small initial size.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadHtmlString(buildHtml(selectedInterval));
      setState(() => isReady = true);
    });
  }

  String buildHtml(String interval) {
    return """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
body, html {
margin:0;
padding:0;
width:100%;
height:100%;
background:#0d1117;
overflow:hidden;
}
.tradingview-widget-container {
width:100%;
height:100%;
}
</style>
</head>
<body>
<div class="tradingview-widget-container">
  <div id="tv_chart"></div>
</div>
<script src="https://s3.tradingview.com/tv.js"></script>
<script>
new TradingView.widget({
  "autosize": true,
  "symbol": "CAPITALCOM:US100",
  "interval": "$interval",
  "timezone": "Etc/UTC",
  "theme": "dark",
  "style": "1",
  "locale": "en",
  "toolbar_bg": "#0d1117",
  "enable_publishing": false,
  "hide_top_toolbar": false,
  "hide_legend": false,
  "save_image": false,
  "container_id": "tv_chart"
});
</script>
</body>
</html>
""";
  }

  void initChart(String interval) {
    controller.loadHtmlString(buildHtml(interval));
  }

  void changeInterval(String value) {
    if (value == selectedInterval) return;
    setState(() {
      selectedInterval = value;
      initChart(value);
    });
  }

  void openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenChartScreen(interval: selectedInterval),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fill whatever space the parent (e.g. Expanded) gives this widget,
    // instead of forcing a fixed height that ignores the real layout.
    return SizedBox.expand(
      child: Container(
        color: const Color(0xff0d1117),
        child: Stack(
          children: [
            if (isReady)
              Positioned.fill(
                child: WebViewWidget(controller: controller),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: openFullScreen,
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                tooltip: "Full screen",
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenChartScreen extends StatefulWidget {
  final String interval;

  const FullScreenChartScreen({super.key, required this.interval});

  @override
  State<FullScreenChartScreen> createState() =>
      _FullScreenChartScreenState();
}

class _FullScreenChartScreenState extends State<FullScreenChartScreen> {
  late WebViewController controller;
  bool isReady = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    _goFullScreen();
  }

  Future<void> _goFullScreen() async {
    // Hide status bar / nav bar and rotate to landscape
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Wait for the orientation change / rebuild to actually complete before
    // loading the chart, otherwise TradingView's autosize calculates using
    // the old (portrait) screen size and the chart looks half-filled.
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    controller.loadHtmlString(_buildHtml(widget.interval));
    setState(() => isReady = true);
  }

  String _buildHtml(String interval) {
    return """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
body, html {
margin:0;
padding:0;
width:100%;
height:100%;
background:#0d1117;
overflow:hidden;
}
.tradingview-widget-container {
width:100%;
height:100%;
}
</style>
</head>
<body>
<div class="tradingview-widget-container">
  <div id="tv_chart"></div>
</div>
<script src="https://s3.tradingview.com/tv.js"></script>
<script>
new TradingView.widget({
  "autosize": true,
  "symbol": "CAPITALCOM:US100",
  "interval": "$interval",
  "timezone": "Etc/UTC",
  "theme": "dark",
  "style": "1",
  "locale": "en",
  "toolbar_bg": "#0d1117",
  "enable_publishing": false,
  "hide_top_toolbar": true,
  "hide_legend": false,
  "save_image": false,
  "container_id": "tv_chart"
});
</script>
</body>
</html>
""";
  }

  @override
  void dispose() {
    // Restore normal UI when leaving full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0d1117),
      body: Stack(
        children: [
          if (isReady)
            Positioned.fill(
              child: WebViewWidget(controller: controller),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}