import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../service/chart_workspace.dart';
import '../service/us100_quote_service.dart';
import 'trade_levels_overlay.dart';

class ChartScreen extends StatefulWidget {
  final bool visible;
  final bool compact;
  final String displaySymbol;

  const ChartScreen({
    super.key,
    this.visible = true,
    this.compact = false,
    this.displaySymbol = ChartWorkspace.defaultDisplaySymbol,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  WebViewController? _controller;
  bool _ready = false;
  bool _immersive = false;
  bool _usedFallbackHtml = false;
  String _loadedSymbol = '';
  bool _loadedFullTools = true;

  static const _desktopUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const _desktopViewport = '''
(function(){
  var m = document.querySelector('meta[name=viewport]');
  if (!m) {
    m = document.createElement('meta');
    m.setAttribute('name','viewport');
    document.head.appendChild(m);
  }
  m.setAttribute('content','width=1280, initial-scale=0.28, maximum-scale=3, user-scalable=yes');
  window.dispatchEvent(new Event('resize'));
})();
''';

  static const _priceBridge = '''
(function(){
  if (window.__tmBridge) return;
  window.__tmBridge = true;
  function parsePx(t){
    if (!t) return 0;
    var m = String(t).replace(/\\u00a0/g,' ').match(/\\d{1,3}(?:,\\d{3})+(?:\\.\\d+)?|\\d{4,}(?:\\.\\d+)?/);
    if (!m) return 0;
    var n = parseFloat(m[0].replace(/,/g,''));
    return (n >= 50 && n <= 5000000) ? n : 0;
  }
  function read(){
    var n = 0;
    var sels = [
      '.js-symbol-last',
      '[class*="js-symbol-last"]',
      '[class*="lastValue-"]',
      '[class*="valueValue-"]',
      '[data-name="legend-source-item"] [class*="valueValue"]',
      '.tv-symbol-price-quote__value'
    ];
    for (var i = 0; i < sels.length && !n; i++) {
      var nodes = document.querySelectorAll(sels[i]);
      for (var j = 0; j < nodes.length && !n; j++) {
        n = parsePx(nodes[j].textContent);
      }
    }
    if (!n) n = parsePx(document.title);
    if (n && window.TmQuote) TmQuote.postMessage(String(n));
  }
  setInterval(read, 700);
  setTimeout(read, 400);
  read();
})();
''';

  bool get _fullTools => !widget.compact;

  @override
  void initState() {
    super.initState();
    _open(widget.displaySymbol, _fullTools);
  }

  @override
  void didUpdateWidget(ChartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final toolsChanged = oldWidget.compact != widget.compact;
    final symbolChanged = oldWidget.displaySymbol != widget.displaySymbol;
    if (symbolChanged || toolsChanged) {
      _open(widget.displaySymbol, _fullTools, force: true);
    } else if (widget.visible && !oldWidget.visible) {
      _resize();
      _injectPriceBridge();
    }
  }

  Future<void> _open(String displaySymbol, bool fullTools,
      {bool force = false}) async {
    if (!force &&
        _loadedSymbol == displaySymbol &&
        _loadedFullTools == fullTools &&
        _controller != null) {
      return;
    }
    _usedFallbackHtml = false;
    final interval = await ChartWorkspace.loadInterval();
    await ChartWorkspace.saveSymbol(displaySymbol);

    if (_controller == null) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0D1117))
        ..setUserAgent(_desktopUa)
        ..addJavaScriptChannel(
          'TmQuote',
          onMessageReceived: (message) {
            final n = double.tryParse(message.message);
            if (n != null) {
              Us100QuoteService.instance.ingestChartLast(n);
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              _resize();
              _injectPriceBridge();
            },
            onWebResourceError: (error) {
              if (_usedFallbackHtml) return;
              _usedFallbackHtml = true;
              _controller?.loadHtmlString(
                _fallbackHtml(displaySymbol, interval, fullTools),
              );
            },
          ),
        );
      _controller = controller;
    }

    _loadedSymbol = displaySymbol;
    _loadedFullTools = fullTools;
    await _controller!.loadRequest(
      ChartWorkspace.embedUri(
        displaySymbol: displaySymbol,
        interval: interval,
        fullTools: fullTools,
      ),
    );
    if (mounted) setState(() => _ready = true);
  }

  void _injectPriceBridge() {
    _controller?.runJavaScript(_priceBridge);
    if (_fullTools) {
      _controller?.runJavaScript(_desktopViewport);
    }
  }

  void _resize() {
    _controller?.runJavaScript(
      "window.dispatchEvent(new Event('resize'));",
    );
  }

  Future<void> _toggleImmersive() async {
    final next = !_immersive;
    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (mounted) {
      setState(() => _immersive = next);
      Future.delayed(const Duration(milliseconds: 350), () {
        _resize();
        _injectPriceBridge();
      });
    }
  }

  @override
  void dispose() {
    if (_immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }

  String _fallbackHtml(String display, String interval, bool fullTools) {
    return ChartWorkspace.widgetHtml(
      displaySymbol: display,
      interval: interval,
      fullTools: fullTools,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Container(
      color: const Color(0xff0d1117),
      child: Stack(
        children: [
          if (_ready && controller != null)
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
          if (widget.compact) const Positioned.fill(child: TradeLevelsOverlay()),
          Positioned(
            bottom: 16,
            right: 8,
            child: IconButton(
              onPressed: _toggleImmersive,
              icon: Icon(
                _immersive ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
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
