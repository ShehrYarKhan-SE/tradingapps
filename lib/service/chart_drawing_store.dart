import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'user_account_store.dart';

class ChartPoint {
  final double x;
  final double p;
  final double y;

  const ChartPoint({required this.x, required this.p, required this.y});

  Map<String, dynamic> toJson() => {'x': x, 'p': p, 'y': y};

  factory ChartPoint.fromJson(Map<String, dynamic> json) => ChartPoint(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        p: (json['p'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0.5,
      );
}

class DrawingTool {
  final String id;
  final String label;
  final String category;
  final IconData icon;
  final String mode; // tap1, drag, freehand, poly, tap3

  const DrawingTool({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
    this.mode = 'drag',
  });
}

class ChartShape {
  final String id;
  final String symbol;
  final String type;
  final List<ChartPoint> points;
  final String? text;
  final int color;
  final double stroke;

  const ChartShape({
    required this.id,
    required this.symbol,
    required this.type,
    required this.points,
    this.text,
    this.color = 0xFF2962FF,
    this.stroke = 1.6,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'type': type,
        'points': points.map((e) => e.toJson()).toList(),
        'text': text,
        'color': color,
        'stroke': stroke,
      };

  factory ChartShape.fromJson(Map<String, dynamic> json) {
    final rawPts = json['points'];
    var points = <ChartPoint>[];
    if (rawPts is List && rawPts.isNotEmpty) {
      points = rawPts
          .whereType<Map>()
          .map((e) => ChartPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      points = [
        ChartPoint(
          x: (json['x1'] as num?)?.toDouble() ?? 0,
          p: (json['p1'] as num?)?.toDouble() ?? 0,
          y: (json['y1'] as num?)?.toDouble() ?? 0.5,
        ),
        ChartPoint(
          x: (json['x2'] as num?)?.toDouble() ?? 0,
          p: (json['p2'] as num?)?.toDouble() ?? 0,
          y: (json['y2'] as num?)?.toDouble() ?? 0.5,
        ),
      ];
    }
    return ChartShape(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? '',
      type: json['type'] as String? ?? 'trend',
      points: points,
      text: json['text'] as String?,
      color: (json['color'] as num?)?.toInt() ?? 0xFF2962FF,
      stroke: (json['stroke'] as num?)?.toDouble() ?? 1.6,
    );
  }

  ChartShape copyWith({String? id, List<ChartPoint>? points}) => ChartShape(
        id: id ?? this.id,
        symbol: symbol,
        type: type,
        points: points ?? this.points,
        text: text,
        color: color,
        stroke: stroke,
      );
}

class ChartDrawingCatalog {
  static const pointer = DrawingTool(
    id: 'pointer',
    label: 'Cursor',
    category: 'Tools',
    icon: Icons.near_me_outlined,
    mode: 'tap1',
  );

  static const tools = <DrawingTool>[
    pointer,
    DrawingTool(id: 'eraser', label: 'Eraser', category: 'Tools', icon: Icons.auto_fix_high, mode: 'tap1'),
    DrawingTool(id: 'text', label: 'Text', category: 'Tools', icon: Icons.text_fields, mode: 'tap1'),
    DrawingTool(id: 'measure', label: 'Measure', category: 'Tools', icon: Icons.straighten, mode: 'drag'),
    DrawingTool(id: 'cross', label: 'Cross line', category: 'Tools', icon: Icons.add, mode: 'tap1'),
    DrawingTool(id: 'trend', label: 'Trend line', category: 'Trend lines', icon: Icons.show_chart, mode: 'drag'),
    DrawingTool(id: 'ray', label: 'Ray', category: 'Trend lines', icon: Icons.arrow_right_alt, mode: 'drag'),
    DrawingTool(id: 'extended', label: 'Extended line', category: 'Trend lines', icon: Icons.linear_scale, mode: 'drag'),
    DrawingTool(id: 'hline', label: 'Horizontal line', category: 'Trend lines', icon: Icons.horizontal_rule, mode: 'tap1'),
    DrawingTool(id: 'hray', label: 'Horizontal ray', category: 'Trend lines', icon: Icons.west, mode: 'drag'),
    DrawingTool(id: 'vline', label: 'Vertical line', category: 'Trend lines', icon: Icons.align_vertical_center, mode: 'tap1'),
    DrawingTool(id: 'channel', label: 'Parallel channel', category: 'Trend lines', icon: Icons.view_stream, mode: 'tap3'),
    DrawingTool(id: 'infoline', label: 'Info line', category: 'Trend lines', icon: Icons.timeline, mode: 'drag'),
    DrawingTool(id: 'fib', label: 'Fib Retracement', category: 'Gann and Fibonacci', icon: Icons.stacked_line_chart, mode: 'drag'),
    DrawingTool(id: 'fibext', label: 'Trend-Based Fib Extension', category: 'Gann and Fibonacci', icon: Icons.stacked_bar_chart, mode: 'tap3'),
    DrawingTool(id: 'fibchannel', label: 'Fib Channel', category: 'Gann and Fibonacci', icon: Icons.view_week, mode: 'tap3'),
    DrawingTool(id: 'fibtime', label: 'Fib Time Zone', category: 'Gann and Fibonacci', icon: Icons.more_vert, mode: 'drag'),
    DrawingTool(id: 'fibfan', label: 'Fib Speed Resistance Fan', category: 'Gann and Fibonacci', icon: Icons.wifi_tethering, mode: 'drag'),
    DrawingTool(id: 'fibtimetrend', label: 'Trend-Based Fib Time', category: 'Gann and Fibonacci', icon: Icons.more_horiz, mode: 'drag'),
    DrawingTool(id: 'fibcircles', label: 'Fib Circles', category: 'Gann and Fibonacci', icon: Icons.radio_button_unchecked, mode: 'drag'),
    DrawingTool(id: 'fibspiral', label: 'Fib Spiral', category: 'Gann and Fibonacci', icon: Icons.sync, mode: 'drag'),
    DrawingTool(id: 'fibarcs', label: 'Fib Speed Resistance Arcs', category: 'Gann and Fibonacci', icon: Icons.architecture, mode: 'drag'),
    DrawingTool(id: 'fibwedge', label: 'Fib Wedge', category: 'Gann and Fibonacci', icon: Icons.change_history, mode: 'tap3'),
    DrawingTool(id: 'pitchfan', label: 'Pitchfan', category: 'Gann and Fibonacci', icon: Icons.filter_tilt_shift, mode: 'tap3'),
    DrawingTool(id: 'gannbox', label: 'Gann Box', category: 'Gann and Fibonacci', icon: Icons.grid_4x4, mode: 'drag'),
    DrawingTool(id: 'brush', label: 'Brush', category: 'Geometric shapes', icon: Icons.brush, mode: 'freehand'),
    DrawingTool(id: 'highlighter', label: 'Highlighter', category: 'Geometric shapes', icon: Icons.highlight, mode: 'freehand'),
    DrawingTool(id: 'arrowmarker', label: 'Arrow Marker', category: 'Geometric shapes', icon: Icons.north_east, mode: 'drag'),
    DrawingTool(id: 'arrow', label: 'Arrow', category: 'Geometric shapes', icon: Icons.arrow_forward, mode: 'drag'),
    DrawingTool(id: 'arrowup', label: 'Arrow Marker Up', category: 'Geometric shapes', icon: Icons.arrow_upward, mode: 'tap1'),
    DrawingTool(id: 'arrowdown', label: 'Arrow Marker Down', category: 'Geometric shapes', icon: Icons.arrow_downward, mode: 'tap1'),
    DrawingTool(id: 'rect', label: 'Rectangle', category: 'Geometric shapes', icon: Icons.crop_square, mode: 'drag'),
    DrawingTool(id: 'rotrect', label: 'Rotated Rectangle', category: 'Geometric shapes', icon: Icons.crop_rotate, mode: 'drag'),
    DrawingTool(id: 'path', label: 'Path', category: 'Geometric shapes', icon: Icons.gesture, mode: 'poly'),
    DrawingTool(id: 'circle', label: 'Circle', category: 'Geometric shapes', icon: Icons.circle_outlined, mode: 'drag'),
    DrawingTool(id: 'ellipse', label: 'Ellipse', category: 'Geometric shapes', icon: Icons.lens_outlined, mode: 'drag'),
    DrawingTool(id: 'polyline', label: 'Polyline', category: 'Geometric shapes', icon: Icons.polyline, mode: 'poly'),
    DrawingTool(id: 'long', label: 'Long Position', category: 'Forecasting and measurement', icon: Icons.trending_up, mode: 'drag'),
    DrawingTool(id: 'short', label: 'Short Position', category: 'Forecasting and measurement', icon: Icons.trending_down, mode: 'drag'),
    DrawingTool(id: 'pricerange', label: 'Price Range', category: 'Forecasting and measurement', icon: Icons.swap_vert, mode: 'drag'),
    DrawingTool(id: 'daterange', label: 'Date Range', category: 'Forecasting and measurement', icon: Icons.swap_horiz, mode: 'drag'),
    DrawingTool(id: 'forecast', label: 'Forecast', category: 'Forecasting and measurement', icon: Icons.moving, mode: 'drag'),
    DrawingTool(id: 'ghost', label: 'Projection', category: 'Forecasting and measurement', icon: Icons.alt_route, mode: 'drag'),
  ];

  static const categories = [
    'Tools',
    'Trend lines',
    'Gann and Fibonacci',
    'Geometric shapes',
    'Forecasting and measurement',
  ];

  static DrawingTool byId(String id) =>
      tools.firstWhere((t) => t.id == id, orElse: () => pointer);
}

class ChartDrawingStore extends ChangeNotifier {
  ChartDrawingStore._();
  static final ChartDrawingStore instance = ChartDrawingStore._();

  final List<ChartShape> items = [];
  final List<String> _undo = [];
  bool _listening = false;
  String? _appliedUpdatedAt;

  List<ChartShape> forSymbol(String symbol) =>
      items.where((e) => e.symbol == symbol).toList();

  bool get canUndo => _undo.isNotEmpty;

  void bind() {
    final store = UserAccountStore.instance;
    if (!_listening) {
      _listening = true;
      store.addListener(_onAccount);
    }
    _hydrate(force: true);
  }

  void _onAccount() => _hydrate();

  void _hydrate({bool force = false}) {
    final store = UserAccountStore.instance;
    if (!force && store.updatedAtIso == _appliedUpdatedAt) return;
    items
      ..clear()
      ..addAll(_decode(store.chartDrawings));
    _appliedUpdatedAt = store.updatedAtIso;
    notifyListeners();
  }

  List<ChartShape> _decode(Map<String, dynamic> raw) {
    final out = <ChartShape>[];
    raw.forEach((symbol, value) {
      if (value is! List) return;
      for (final e in value) {
        if (e is! Map) continue;
        final shape = ChartShape.fromJson(Map<String, dynamic>.from(e));
        if (shape.id.isEmpty) continue;
        out.add(ChartShape(
          id: shape.id,
          symbol: shape.symbol.isEmpty ? symbol : shape.symbol,
          type: shape.type,
          points: shape.points,
          text: shape.text,
          color: shape.color,
          stroke: shape.stroke,
        ));
      }
    });
    return out;
  }

  Map<String, dynamic> _encode() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final s in items) {
      map.putIfAbsent(s.symbol, () => []).add(s.toJson());
    }
    return map;
  }

  Future<void> _persist() async {
    UserAccountStore.instance.chartDrawings = _encode();
    await UserAccountStore.instance.saveAll();
    _appliedUpdatedAt = UserAccountStore.instance.updatedAtIso;
  }

  Future<void> add(ChartShape shape) async {
    items.removeWhere((e) => e.id == shape.id);
    items.add(shape);
    _undo.add(shape.id);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    items.removeWhere((e) => e.id == id);
    _undo.remove(id);
    notifyListeners();
    await _persist();
  }

  Future<void> undo() async {
    if (_undo.isEmpty) return;
    await remove(_undo.removeLast());
  }

  Future<void> clearSymbol(String symbol) async {
    items.removeWhere((e) => e.symbol == symbol);
    _undo.clear();
    notifyListeners();
    await _persist();
  }

  void resetMemory() {
    items.clear();
    _undo.clear();
    _appliedUpdatedAt = null;
    notifyListeners();
  }
}
