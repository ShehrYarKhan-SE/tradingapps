import 'dart:math';

import 'package:flutter/material.dart';

import '../service/chart_drawing_store.dart';
import '../service/chart_scale_service.dart';

class ChartDrawingLayer extends StatefulWidget {
  final String symbol;
  final DrawingTool tool;
  final bool interactive;
  final VoidCallback? onFinished;

  const ChartDrawingLayer({
    super.key,
    required this.symbol,
    required this.tool,
    required this.interactive,
    this.onFinished,
  });

  @override
  State<ChartDrawingLayer> createState() => _ChartDrawingLayerState();
}

class _ChartDrawingLayerState extends State<ChartDrawingLayer> {
  final _store = ChartDrawingStore.instance;
  final _scale = ChartScaleService.instance;
  final _poly = <ChartPoint>[];
  Offset? _start;
  Offset? _current;
  ChartShape? _draft;
  DateTime? _lastTap;

  DrawingTool get _tool => widget.tool;

  @override
  void initState() {
    super.initState();
    _store.addListener(_tick);
    _scale.addListener(_tick);
  }

  @override
  void didUpdateWidget(covariant ChartDrawingLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tool.id != widget.tool.id) {
      _poly.clear();
      _draft = null;
      _start = null;
    }
  }

  @override
  void dispose() {
    _store.removeListener(_tick);
    _scale.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  ChartPoint _ptOf(Offset local, Size size) => ChartPoint(
        x: (local.dx / size.width).clamp(0.0, 1.0),
        p: _scale.priceOf(local.dy) ?? 0,
        y: (local.dy / size.height).clamp(0.0, 1.0),
      );

  Offset _toScreen(ChartPoint p, Size size) {
    final mapped = _scale.yOf(p.p);
    final y = (mapped != null && _scale.ready && p.p != 0)
        ? mapped
        : p.y * size.height;
    return Offset(p.x * size.width, y);
  }

  Future<void> _commit(ChartShape shape) async {
    await _store.add(
      shape.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString()),
    );
    widget.onFinished?.call();
  }

  Future<void> _askText(Offset local, Size size) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B2E),
        title: const Text('Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    await _commit(ChartShape(
      id: 'draft',
      symbol: widget.symbol,
      type: 'text',
      points: [_ptOf(local, size)],
      text: text,
      color: 0xFFE5E7EB,
    ));
  }

  void _eraseAt(Offset local, Size size) {
    String? bestId;
    var best = 24.0;
    for (final shape in _store.forSymbol(widget.symbol)) {
      final d = _hit(shape, local, size);
      if (d != null && d < best) {
        best = d;
        bestId = shape.id;
      }
    }
    if (bestId != null) _store.remove(bestId);
  }

  double? _hit(ChartShape shape, Offset local, Size size) {
    if (shape.points.isEmpty) return null;
    final screens = shape.points.map((p) => _toScreen(p, size)).toList();
    switch (shape.type) {
      case 'hline':
      case 'pricerange':
        return screens.map((o) => (local.dy - o.dy).abs()).reduce(min);
      case 'vline':
      case 'daterange':
        return screens.map((o) => (local.dx - o.dx).abs()).reduce(min);
      case 'text':
      case 'cross':
      case 'arrowup':
      case 'arrowdown':
        return (local - screens.first).distance;
      case 'rect':
      case 'ellipse':
      case 'gannbox':
      case 'long':
      case 'short':
        if (screens.length < 2) return (local - screens.first).distance;
        final r = Rect.fromPoints(screens[0], screens[1]).inflate(10);
        return r.contains(local) ? 8 : null;
      case 'circle':
      case 'fibcircles':
      case 'fibarcs':
      case 'fibspiral':
        if (screens.length < 2) return null;
        return ((local - screens[0]).distance - (screens[1] - screens[0]).distance).abs();
      default:
        var best = double.infinity;
        for (var i = 0; i < screens.length; i++) {
          best = min(best, (local - screens[i]).distance);
          if (i > 0) {
            best = min(best, _distToSegment(local, screens[i - 1], screens[i]));
          }
        }
        return best;
    }
  }

  ChartShape _shape(List<ChartPoint> pts) {
    final id = _tool.id;
    final color = switch (id) {
      'hline' || 'hray' || 'pricerange' => 0xFFF59E0B,
      'rect' || 'rotrect' || 'circle' || 'ellipse' => 0xFF26A69A,
      'fib' || 'fibext' || 'fibchannel' || 'fibtime' || 'fibfan' || 'fibcircles' || 'fibspiral' || 'fibarcs' || 'fibwedge' || 'pitchfan' || 'gannbox' || 'fibtimetrend' => 0xFFA855F7,
      'highlighter' => 0x66FDE047,
      'brush' => 0xFFE5E7EB,
      'long' => 0xFF22C55E,
      'short' => 0xFFEF4444,
      'vline' || 'daterange' => 0xFF22D3EE,
      _ => 0xFF60A5FA,
    };
    return ChartShape(
      id: 'draft',
      symbol: widget.symbol,
      type: id,
      points: pts,
      color: color,
      stroke: id == 'highlighter' ? 10 : 1.7,
    );
  }

  Future<void> _onDown(Offset local, Size size) async {
    final tool = _tool;
    if (tool.id == 'pointer') return;
    if (tool.id == 'eraser') {
      _eraseAt(local, size);
      return;
    }
    if (tool.id == 'text') {
      await _askText(local, size);
      return;
    }
    if (tool.mode == 'tap1') {
      final p = _ptOf(local, size);
      await _commit(_shape([p, p]));
      return;
    }
    if (tool.mode == 'poly') {
      final now = DateTime.now();
      final dbl = _lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 280);
      _lastTap = now;
      if (dbl && _poly.length >= 2) {
        await _commit(_shape(List.of(_poly)));
        _poly.clear();
        setState(() => _draft = null);
        return;
      }
      _poly.add(_ptOf(local, size));
      setState(() => _draft = _shape(List.of(_poly)));
      return;
    }
    if (tool.mode == 'tap3') {
      _poly.add(_ptOf(local, size));
      setState(() => _draft = _shape(List.of(_poly)));
      if (_poly.length >= 3) {
        await _commit(_shape(List.of(_poly)));
        _poly.clear();
        setState(() => _draft = null);
      }
      return;
    }
    setState(() {
      _start = local;
      _current = local;
      _poly
        ..clear()
        ..add(_ptOf(local, size));
      _draft = _shape(List.of(_poly)..add(_ptOf(local, size)));
    });
  }

  void _onMove(Offset local, Size size) {
    if (_start == null && _tool.mode != 'freehand' && _tool.mode != 'poly') return;
    if (_tool.mode == 'poly' || _tool.mode == 'tap3') return;
    setState(() {
      _current = local;
      if (_tool.mode == 'freehand') {
        _poly.add(_ptOf(local, size));
        _draft = _shape(List.of(_poly));
      } else if (_start != null) {
        _draft = _shape([_ptOf(_start!, size), _ptOf(local, size)]);
      }
    });
  }

  Future<void> _onUp(Offset local, Size size) async {
    if (_tool.mode == 'poly' || _tool.mode == 'tap3' || _tool.mode == 'tap1') return;
    final draft = _draft;
    final start = _start;
    _start = null;
    _current = null;
    setState(() => _draft = null);
    if (draft == null) return;
    if (_tool.mode == 'freehand') {
      if (_poly.length < 2) {
        _poly.clear();
        return;
      }
      await _commit(_shape(List.of(_poly)));
      _poly.clear();
      return;
    }
    if (start != null && (start - local).distance < 8 && _tool.id != 'hline' && _tool.id != 'vline') {
      return;
    }
    await _commit(draft);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return Listener(
          behavior: widget.interactive
              ? HitTestBehavior.opaque
              : HitTestBehavior.translucent,
          onPointerDown: widget.interactive ? (e) => _onDown(e.localPosition, size) : null,
          onPointerMove: widget.interactive ? (e) => _onMove(e.localPosition, size) : null,
          onPointerUp: widget.interactive ? (e) => _onUp(e.localPosition, size) : null,
          child: CustomPaint(
            size: size,
            painter: _DrawingPainter(
              shapes: [
                ..._store.forSymbol(widget.symbol),
                if (_draft != null) _draft!,
              ],
              scale: _scale,
              hint: _tool.mode == 'poly' && _poly.isNotEmpty
                  ? 'Double-tap to finish'
                  : _tool.mode == 'tap3' && _poly.isNotEmpty
                      ? '${_poly.length}/3 points'
                      : null,
            ),
          ),
        );
      },
    );
  }
}

double _distToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final t = ab.dx * ab.dx + ab.dy * ab.dy;
  if (t < 1e-6) return (p - a).distance;
  var u = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / t;
  u = u.clamp(0.0, 1.0);
  final proj = Offset(a.dx + u * ab.dx, a.dy + u * ab.dy);
  return (p - proj).distance;
}

class _DrawingPainter extends CustomPainter {
  final List<ChartShape> shapes;
  final ChartScaleService scale;
  final String? hint;

  _DrawingPainter({required this.shapes, required this.scale, this.hint});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shapes) {
      _paintShape(canvas, size, s);
    }
    if (hint != null) {
      _label(canvas, const Offset(12, 12), hint!, 0xFF93C5FD);
    }
  }

  Offset _map(ChartPoint p, Size size) {
    final mapped = scale.yOf(p.p);
    final y = (mapped != null && scale.ready && p.p != 0)
        ? mapped
        : p.y * size.height;
    return Offset(p.x * size.width, y);
  }

  void _paintShape(Canvas canvas, Size size, ChartShape s) {
    if (s.points.isEmpty) return;
    final pts = s.points.map((p) => _map(p, size)).toList();
    final a = pts.first;
    final b = pts.length > 1 ? pts[1] : a;
    final c = pts.length > 2 ? pts[2] : b;
    final paint = Paint()
      ..color = Color(s.color)
      ..strokeWidth = s.stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (s.type) {
      case 'hline':
        canvas.drawLine(Offset(0, a.dy), Offset(size.width, a.dy), paint);
        _label(canvas, Offset(8, a.dy - 14), s.points.first.p.toStringAsFixed(2), s.color);
      case 'hray':
        canvas.drawLine(a, Offset(size.width, a.dy), paint);
      case 'vline':
        canvas.drawLine(Offset(a.dx, 0), Offset(a.dx, size.height), paint);
      case 'cross':
        canvas.drawLine(Offset(0, a.dy), Offset(size.width, a.dy), paint);
        canvas.drawLine(Offset(a.dx, 0), Offset(a.dx, size.height), paint);
      case 'ray':
      case 'forecast':
      case 'ghost':
        _ray(canvas, a, b, size, paint, dashed: s.type == 'ghost');
      case 'extended':
        _ray(canvas, a, b, size, paint);
        _ray(canvas, b, a, size, paint);
      case 'infoline':
        canvas.drawLine(a, b, paint);
        _label(canvas, b.translate(6, -10), '${(s.points.last.p - s.points.first.p).toStringAsFixed(1)}', s.color);
      case 'channel':
        canvas.drawLine(a, b, paint);
        final delta = c - Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        canvas.drawLine(a + delta, b + delta, paint);
      case 'rect':
      case 'rotrect':
        _rect(canvas, a, b, paint, rotate: s.type == 'rotrect');
      case 'circle':
        canvas.drawCircle(a, (b - a).distance, paint);
      case 'ellipse':
        canvas.drawOval(Rect.fromPoints(a, b), paint);
      case 'fib':
        _fibLevels(canvas, size, a, b, s.points, s.color, vertical: false);
      case 'fibtime':
      case 'fibtimetrend':
        _fibLevels(canvas, size, a, b, s.points, s.color, vertical: true);
      case 'fibext':
        _fibExt(canvas, size, a, b, c, s.color);
      case 'fibchannel':
        _fibChannel(canvas, a, b, c, s.color);
      case 'fibfan':
      case 'pitchfan':
        _fan(canvas, a, b, c, s.color);
      case 'fibcircles':
        _fibCircles(canvas, a, b, s.color);
      case 'fibspiral':
        _spiral(canvas, a, b, paint);
      case 'fibarcs':
        _arcs(canvas, a, b, s.color);
      case 'fibwedge':
        _wedge(canvas, a, b, c, paint);
      case 'gannbox':
        _gann(canvas, a, b, paint);
      case 'brush':
      case 'highlighter':
      case 'path':
      case 'polyline':
        _poly(canvas, pts, paint);
      case 'arrow':
      case 'arrowmarker':
        _arrow(canvas, a, b, paint);
      case 'arrowup':
        _arrow(canvas, Offset(a.dx, a.dy + 28), Offset(a.dx, a.dy - 28), paint);
      case 'arrowdown':
        _arrow(canvas, Offset(a.dx, a.dy - 28), Offset(a.dx, a.dy + 28), paint);
      case 'text':
        _label(canvas, a, s.text ?? '', s.color);
      case 'measure':
        canvas.drawLine(a, b, paint);
        _label(canvas, Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 12),
            '${(s.points.last.p - s.points.first.p).abs().toStringAsFixed(1)}', s.color);
      case 'long':
      case 'short':
        _position(canvas, a, b, s.type == 'long', s.color);
      case 'pricerange':
        canvas.drawLine(Offset(0, a.dy), Offset(size.width, a.dy), paint);
        canvas.drawLine(Offset(0, b.dy), Offset(size.width, b.dy), paint);
        _label(canvas, Offset(8, (a.dy + b.dy) / 2),
            '${(s.points.last.p - s.points.first.p).abs().toStringAsFixed(1)}', s.color);
      case 'daterange':
        canvas.drawLine(Offset(a.dx, 0), Offset(a.dx, size.height), paint);
        canvas.drawLine(Offset(b.dx, 0), Offset(b.dx, size.height), paint);
      default:
        canvas.drawLine(a, b, paint);
        canvas.drawCircle(a, 3, Paint()..color = Color(s.color));
        canvas.drawCircle(b, 3, Paint()..color = Color(s.color));
    }
  }

  void _rect(Canvas canvas, Offset a, Offset b, Paint paint, {required bool rotate}) {
    final r = Rect.fromPoints(a, b);
    if (!rotate) {
      canvas.drawRect(r, Paint()..color = paint.color.withValues(alpha: 0.12)..style = PaintingStyle.fill);
      canvas.drawRect(r, paint);
      return;
    }
    final c = r.center;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(atan2(b.dy - a.dy, b.dx - a.dx) * 0.25);
    final rr = Rect.fromCenter(center: Offset.zero, width: r.width, height: r.height);
    canvas.drawRect(rr, Paint()..color = paint.color.withValues(alpha: 0.12)..style = PaintingStyle.fill);
    canvas.drawRect(rr, paint);
    canvas.restore();
  }

  void _poly(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _arrow(Canvas canvas, Offset a, Offset b, Paint paint) {
    canvas.drawLine(a, b, paint);
    final d = b - a;
    if (d.distance < 1) return;
    final n = d / d.distance;
    final left = Offset(-n.dy, n.dx);
    final tip = b;
    final p1 = tip - n * 12 + left * 7;
    final p2 = tip - n * 12 - left * 7;
    canvas.drawPath(Path()..moveTo(tip.dx, tip.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close(),
        Paint()..color = paint.color..style = PaintingStyle.fill);
  }

  void _ray(Canvas canvas, Offset a, Offset b, Size size, Paint paint, {bool dashed = false}) {
    final path = Path()..moveTo(a.dx, a.dy);
    final d = b - a;
    if (d.distance < 1) {
      canvas.drawLine(a, b, paint);
      return;
    }
    final n = d / d.distance;
    var end = b;
    for (var i = 0; i < 5000; i++) {
      end += n * 8;
      if (end.dx < -40 || end.dy < -40 || end.dx > size.width + 40 || end.dy > size.height + 40) break;
    }
    if (dashed) {
      _dash(canvas, a, end, paint);
    } else {
      path.lineTo(end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final n = d / len;
    var t = 0.0;
    var on = true;
    while (t < len) {
      final next = min(t + (on ? 8 : 6), len);
      if (on) canvas.drawLine(a + n * t, a + n * next, paint);
      t = next;
      on = !on;
    }
  }

  void _fibLevels(Canvas canvas, Size size, Offset a, Offset b, List<ChartPoint> pts, int color, {required bool vertical}) {
    const levels = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.272, 1.618];
    for (final lv in levels) {
      final paint = Paint()
        ..color = Color(color).withValues(alpha: lv == 0.618 ? 1 : 0.75)
        ..strokeWidth = lv == 0.5 ? 1.8 : 1.05;
      if (vertical) {
        final x = a.dx + (b.dx - a.dx) * lv;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        _label(canvas, Offset(x + 4, 10), lv.toStringAsFixed(3), color);
      } else {
        final y = a.dy + (b.dy - a.dy) * lv;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        _label(canvas, Offset(8, y - 12), lv.toStringAsFixed(3), color);
      }
    }
  }

  void _fibExt(Canvas canvas, Size size, Offset a, Offset b, Offset c, int color) {
    final d = b - a;
    const levels = [0.0, 0.618, 1.0, 1.272, 1.618, 2.0];
    for (final lv in levels) {
      final p = c + d * lv;
      final paint = Paint()..color = Color(color)..strokeWidth = 1.1;
      canvas.drawLine(Offset(0, p.dy), Offset(size.width, p.dy), paint);
      _label(canvas, Offset(8, p.dy - 12), lv.toStringAsFixed(3), color);
    }
  }

  void _fibChannel(Canvas canvas, Offset a, Offset b, Offset c, int color) {
    final paint = Paint()..color = Color(color)..strokeWidth = 1.2;
    canvas.drawLine(a, b, paint);
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final delta = c - mid;
    const levels = [0.0, 0.382, 0.618, 1.0];
    for (final lv in levels) {
      canvas.drawLine(a + delta * lv, b + delta * lv, paint);
    }
  }

  void _fan(Canvas canvas, Offset a, Offset b, Offset c, int color) {
    final paint = Paint()..color = Color(color)..strokeWidth = 1.1;
    const levels = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];
    for (final lv in levels) {
      final target = Offset(b.dx, a.dy + (b.dy - a.dy) * lv);
      canvas.drawLine(a, target, paint);
    }
    canvas.drawLine(a, c, paint);
  }

  void _fibCircles(Canvas canvas, Offset a, Offset b, int color) {
    final r = (b - a).distance;
    const levels = [0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.618];
    for (final lv in levels) {
      canvas.drawCircle(a, r * lv, Paint()..color = Color(color)..style = PaintingStyle.stroke..strokeWidth = 1.1);
    }
  }

  void _spiral(Canvas canvas, Offset a, Offset b, Paint paint) {
    final path = Path()..moveTo(a.dx, a.dy);
    final r0 = max(4.0, (b - a).distance / 8);
    for (var i = 0; i < 90; i++) {
      final t = i / 12;
      final r = r0 * pow(1.618, t / pi);
      path.lineTo(a.dx + r * cos(t), a.dy + r * sin(t));
    }
    canvas.drawPath(path, paint);
  }

  void _arcs(Canvas canvas, Offset a, Offset b, int color) {
    final r = (b - a).distance;
    const levels = [0.382, 0.5, 0.618, 1.0];
    for (final lv in levels) {
      canvas.drawArc(Rect.fromCircle(center: a, radius: r * lv), pi, pi, false,
          Paint()..color = Color(color)..style = PaintingStyle.stroke..strokeWidth = 1.1);
    }
  }

  void _wedge(Canvas canvas, Offset a, Offset b, Offset c, Paint paint) {
    canvas.drawLine(a, b, paint);
    canvas.drawLine(a, c, paint);
    canvas.drawArc(
      Rect.fromCircle(center: a, radius: (b - a).distance),
      atan2(b.dy - a.dy, b.dx - a.dx),
      atan2(c.dy - a.dy, c.dx - a.dx) - atan2(b.dy - a.dy, b.dx - a.dx),
      false,
      paint,
    );
  }

  void _gann(Canvas canvas, Offset a, Offset b, Paint paint) {
    final r = Rect.fromPoints(a, b);
    canvas.drawRect(r, paint);
    for (var i = 1; i < 8; i++) {
      final fx = r.left + r.width * i / 8;
      final fy = r.top + r.height * i / 8;
      canvas.drawLine(Offset(fx, r.top), Offset(fx, r.bottom), paint..strokeWidth = 0.7);
      canvas.drawLine(Offset(r.left, fy), Offset(r.right, fy), paint);
    }
    canvas.drawLine(r.topLeft, r.bottomRight, paint..strokeWidth = 1.2);
    canvas.drawLine(r.topRight, r.bottomLeft, paint);
  }

  void _position(Canvas canvas, Offset a, Offset b, bool isLong, int color) {
    final r = Rect.fromPoints(a, b);
    canvas.drawRect(r, Paint()..color = Color(color).withValues(alpha: 0.12)..style = PaintingStyle.fill);
    canvas.drawRect(r, Paint()..color = Color(color)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    final y = isLong ? r.bottom : r.top;
    canvas.drawLine(Offset(r.left, y), Offset(r.right, y), Paint()..color = Color(color)..strokeWidth = 2);
    _label(canvas, Offset(r.left + 6, r.top + 6), isLong ? 'Long' : 'Short', color);
  }

  void _label(Canvas canvas, Offset at, String text, int color) {
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Color(color), fontSize: 10, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
