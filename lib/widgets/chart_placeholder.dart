import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late WebViewController controller;
  bool isReady = false;
  bool showSideToolbar = true;

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
            Future.delayed(const Duration(milliseconds: 300), () {
              controller.runJavaScript(
                "window.dispatchEvent(new Event('resize'));",
              );
            });
          },
        ),
      );

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
html, body {
  margin:0;
  padding:0;
  background:#0d1117;
  overflow:hidden;
}
.tradingview-widget-container, #tv_chart {
  position:fixed;
  top:0; left:0; right:0; bottom:0;
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
  "width": "100%",
  "height": "100%",
  "symbol": "CAPITALCOM:US100",
  "interval": "$interval",
  "timezone": "Etc/UTC",
  "theme": "dark",
  "style": "1",
  "locale": "en",
  "toolbar_bg": "#0d1117",
  "enable_publishing": false,
  "hide_top_toolbar": false,
  "hide_side_toolbar": ${!showSideToolbar},
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
    return Container(
      color: const Color(0xff0d1117),
      child: Stack(
        children: [
          if (isReady)
            Positioned.fill(
              child: WebViewWidget(
                controller: controller,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                  ),
                },
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            top: 0,
            bottom: 0,
            left: showSideToolbar ? 40 : 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    showSideToolbar = !showSideToolbar;
                    controller.loadHtmlString(buildHtml(selectedInterval));
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(6),
                    ),
                  ),
                  child: Icon(
                    showSideToolbar
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
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
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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
html, body {
  margin:0;
  padding:0;
  background:#0d1117;
  overflow:hidden;
}
.tradingview-widget-container, #tv_chart {
  position:fixed;
  top:0; left:0; right:0; bottom:0;
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
  "width": "100%",
  "height": "100%",
  "symbol": "CAPITALCOM:US100",
  "interval": "$interval",
  "timezone": "Etc/UTC",
  "theme": "dark",
  "style": "1",
  "locale": "en",
  "toolbar_bg": "#0d1117",
  "enable_publishing": false,
  "hide_top_toolbar": true,
  "hide_side_toolbar": false,
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