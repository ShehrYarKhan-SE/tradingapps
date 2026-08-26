import 'package:flutter/material.dart';

class SmcCandle {
  const SmcCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final double open;
  final double high;
  final double low;
  final double close;

  bool get bull => close >= open;
}

enum SmcMarkKind { box, line, tag }

class SmcMark {
  const SmcMark.box({
    required this.i0,
    required this.i1,
    required this.low,
    required this.high,
    required this.label,
    required this.color,
  })  : kind = SmcMarkKind.box,
        price = 0;

  const SmcMark.line({
    required this.price,
    required this.label,
    required this.color,
    this.i0 = 0,
    this.i1 = -1,
  })  : kind = SmcMarkKind.line,
        low = 0,
        high = 0;

  const SmcMark.tag({
    required this.i0,
    required this.price,
    required this.label,
    required this.color,
  })  : kind = SmcMarkKind.tag,
        i1 = i0,
        low = 0,
        high = 0;

  final SmcMarkKind kind;
  final int i0;
  final int i1;
  final double low;
  final double high;
  final double price;
  final String label;
  final Color color;
}

class SmcChart {
  SmcChart({
    required this.timeframe,
    required List<List<double>> ohlc,
    required this.marks,
    this.caption = '',
  }) : candles = [
          for (final r in ohlc)
            SmcCandle(open: r[0], high: r[1], low: r[2], close: r[3]),
        ];

  final String timeframe;
  final List<SmcCandle> candles;
  final List<SmcMark> marks;
  final String caption;
}

class SmcTopic {
  const SmcTopic({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.group,
    required this.what,
    required this.spot,
    required this.use,
    required this.mistake,
    required this.us100,
    required this.chart,
  });

  final String id;
  final String code;
  final String title;
  final String subtitle;
  final String group;
  final String what;
  final String spot;
  final String use;
  final String mistake;
  final String us100;
  final SmcChart chart;
}
