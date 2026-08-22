import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../service/chart_workspace.dart';

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

  bool get _fullTools => !widget.compact;

  @override
  void initState() {
    super.initState();
    _open(widget.displaySymbol, true);
  }

  @override
  void didUpdateWidget(ChartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final toolsChanged = oldWidget.compact != widget.compact;
    final symbolChanged = oldWidget.displaySymbol != widget.displaySymbol;
    if (symbolChanged) {
      _open(widget.displaySymbol, true, force: true);
    } else if ((widget.visible && !oldWidget.visible) || toolsChanged) {
      _resize();
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
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) => _resize(),
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
      Future.delayed(const Duration(milliseconds: 350), _resize);
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
    final uri = ChartWorkspace.embedUri(
      displaySymbol: display,
      interval: interval,
      fullTools: fullTools,
    ).toString();
    return """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
html, body, iframe { margin:0; padding:0; height:100%; width:100%; background:#0d1117; border:0; }
iframe { position:fixed; inset:0; }
</style>
</head>
<body>
<iframe id="${ChartWorkspace.frameIdOf(display)}" src="$uri" allowtransparency="true" scrolling="no" allowfullscreen></iframe>
</body>
</html>
""";
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
