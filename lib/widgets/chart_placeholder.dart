import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../service/chart_workspace.dart';
import '../service/us100_quote_service.dart';
import '../service/ai_coach_service.dart';

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
    var s = String(t).replace(/\\u00a0/g,' ').replace(/,/g,'');
    var m = s.match(/\\d{4,}(?:\\.\\d+)?/);
    if (!m) return 0;
    var n = parseFloat(m[0]);
    return (n >= 50 && n <= 5000000) ? n : 0;
  }
  function docs(){
    var out = [document];
    try {
      var ifs = document.querySelectorAll('iframe');
      for (var i = 0; i < ifs.length; i++) {
        try {
          if (ifs[i].contentDocument) out.push(ifs[i].contentDocument);
        } catch (e) {}
      }
    } catch (e) {}
    return out;
  }
  function collect(){
    var last = 0;
    var samples = [];
    var vw = window.innerWidth || 0;
    var list = docs();
    for (var d = 0; d < list.length; d++) {
      var nodeList = list[d].querySelectorAll('div,span,text');
      for (var i = 0; i < nodeList.length; i++) {
        var el = nodeList[i];
        if (el.childElementCount > 3) continue;
        var text = (el.innerText || el.textContent || '').trim();
        if (!text || text.length > 16) continue;
        var n = parsePx(text);
        if (!n) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 6 || r.height < 6 || r.height > 36) continue;
        if (r.left < vw * 0.58) continue;
        samples.push({p:n, y:r.top + r.height/2, x:r.left});
        var cls = (el.className && String(el.className)) || '';
        if (/last|js-symbol-last|price-axis/i.test(cls) || r.left > vw * 0.78) {
          last = n;
        }
      }
    }
    if (!last && samples.length) {
      samples.sort(function(a,b){ return b.x - a.x; });
      last = samples[0].p;
    }
    if (last && window.TmQuote) TmQuote.postMessage(String(last));
    if (samples.length >= 1 && window.TmScale) {
      samples.sort(function(a,b){ return b.x - a.x; });
      var axisX = samples[0].x;
      var axis = samples.filter(function(s){ return axisX - s.x < 48; });
      window.TmScale.postMessage(JSON.stringify({
        last:last,
        samples:axis.length>=2?axis:samples,
        h: window.innerHeight || 0
      }));
    }
  }
  setInterval(collect, 600);
  setTimeout(collect, 350);
  collect();
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
          if (!widget.compact)
            Positioned(
              bottom: 16,
              left: 8,
              child: TextButton.icon(
                onPressed: () {
                  final text = AiCoachService.instance.explainChart(widget.displaySymbol);
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: const Color(0xFF141B2E),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (ctx) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.auto_awesome, color: Color(0xFFC4B5FD), size: 16),
                label: const Text('Explain this move', style: TextStyle(color: Color(0xFFC4B5FD))),
                style: TextButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
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
