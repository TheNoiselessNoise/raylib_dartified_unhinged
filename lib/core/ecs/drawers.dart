part of '../raylib_dartified_unhinged.dart';

abstract class BaseDrawer<T extends App<T>> with HasAppAccess<T> {
  @override
  final T app;

  BaseDrawer(this.app);
}

class ComponentDrawer<T extends App<T>> extends BaseDrawer<T> {
  ComponentDrawer(super.app);

  void _drawComponentTree(
    Comp<T> node,
    num x,
    num y,
    num fontSize,
    String prefix,
    ColorD color,
    bool isLast,
    List<int> yRef,
  ) {
    final connector = isLast ? '\\ ' : '|- ';
    String label = '$prefix$connector${node.name}';
    if (true) {
      label += ' (entity: ${node.entity})';
    }
    rl.CoreD.DrawText(label, x, yRef[0], fontSize, color);
    yRef[0] += (fontSize + 2).toInt();

    final children = node.getComponents().toList();
    for (int i = 0; i < children.length; i++) {
      final childIsLast = i == children.length - 1;
      final childPrefix = prefix + (isLast ? '    ' : '|   ');
      _drawComponentTree(children[i], x, y, fontSize, childPrefix, color, childIsLast, yRef);
    }
  }

  void tree(
    Comp<T> node,
    num x,
    num y,
    num fontSize,
    String prefix,
    ColorD color,
    [List<int>? yRef]
  ) {
    yRef ??= [y.toInt()];

    bool isLast = false;
    final parent = node.getParentAs<IsAnyComponentManagable<T>>();
    final comps = parent!.getComponents().toList();

    if (comps.indexOf(node) == comps.length - 1) {
      isLast = node.getComponents().isEmpty;
    }

    _drawComponentTree(node, x, y, fontSize, prefix, color, isLast, yRef);
  }

  void entityTree(
    Entity<T> entity,
    num x,
    num y,
    num fontSize, {
      ColorD? color,
      String? prefix,
    }
  ) {
    final yRef = [y.toInt()];
    rl.CoreD.DrawText('$entity', x, y, fontSize, color ?? .WHITE);
    yRef[0] += fontSize.toInt();
    for (final comp in entity.getComponents()) {
      tree(comp, x, yRef[0], fontSize, prefix ?? '', color ?? .WHITE, yRef);
    }
  }
}

class DigitalStyle {
  /// Segment thickness as a fraction of the digit width.
  final double segmentThickness;

  /// Fraction of thickness; controls tip gaps.
  final double segmentSpacing;

  /// If true, segments are drawn with rounded ends (DrawRectangleRounded).
  /// If false, plain rectangles are used.
  final bool roundedEnds;

  /// Roundness factor used when [roundedEnds] is true. Range 0.0–1.0.
  final double roundness;

  const DigitalStyle({
    this.segmentThickness = 0.13,
    this.segmentSpacing = 0,
    this.roundedEnds = false,
    this.roundness = 0.4,
  });

  static const DEFAULT = DigitalStyle();
  static const ROUNDED = DigitalStyle(roundedEnds: true, roundness: 0.5);
  static const THICK = DigitalStyle(segmentThickness: 0.18, roundedEnds: true, roundness: 0.4);
  static const THIN = DigitalStyle(segmentThickness: 0.08, roundedEnds: true, roundness: 0.6);
}

class DigitalDrawer<T extends App<T>> extends BaseDrawer<T> {
  DigitalDrawer(super.app);

  // Segment bitmask indices: a=0, b=1, c=2, d=3, e=4, f=5, g=6
  //
  //  aaa
  // f   b
  // f   b
  //  ggg
  // e   c
  // e   c
  //  ddd
  //
  final Map<String, int> _segmentMap = {
    '0': 0x3F, // 0b0111111
    '1': 0x06, // 0b0000110
    '2': 0x5B, // 0b1011011
    '3': 0x4F, // 0b1001111
    '4': 0x66, // 0b1100110
    '5': 0x6D, // 0b1101101
    '6': 0x7D, // 0b1111101
    '7': 0x07, // 0b0000111
    '8': 0x7F, // 0b1111111
    '9': 0x6F, // 0b1101111
    'A': 0x77, // 0b1110111
    'b': 0x7C, // 0b1111100
    'B': 0x7C, // 0b1111100
    'C': 0x39, // 0b0111001
    'd': 0x5E, // 0b1011110
    'D': 0x5E, // 0b1011110
    'E': 0x79, // 0b1111001
    'F': 0x71, // 0b1110001
  };

  // Segment bit positions
  final int _segA = 1 << 0;
  final int _segB = 1 << 1;
  final int _segC = 1 << 2;
  final int _segD = 1 << 3;
  final int _segE = 1 << 4;
  final int _segF = 1 << 5;
  final int _segG = 1 << 6;

  void text(
    num x,
    num y,
    num digitWidth,
    num digitHeight,
    String text,
    ColorD? digitBackgroundColor,
    ColorD digitUnlitSegmentsColor,
    ColorD digitLitSegmentsColor, {
    DigitalStyle style = .DEFAULT,
    num digitPadding = 1,
    ColorD? textBackgroundColor,
  }) {
    assert(text.isNotEmpty, 'DrawDigitalText expects text to be non-empty.');

    if (textBackgroundColor != null) {
      final totalWidth = (text.length * digitWidth) + ((text.length - 1) * digitPadding);
      rl.CoreD.DrawRectangleRec(
        .rect(x, y, totalWidth, digitHeight),
        textBackgroundColor,
      );
    }

    for (int i = 0; i < text.length; i++) {
      final pad = i > 0 ? digitPadding : 0;
      number(
        .rect(x+(i*digitWidth)+(i*pad), y, digitWidth, digitHeight),
        text[i],
        digitBackgroundColor,
        digitUnlitSegmentsColor,
        digitLitSegmentsColor,
        style: style,
      );
    }
  }

  /// Draws a single hex digit (0–9, A–F) as a 7-segment display inside [dst].
  ///
  /// [dst] => bounding rect for this single digit.
  /// 
  /// [n] => a single character string: '0'–'9', 'A'–'F' (case-insensitive for A–F).
  ///          Unknown characters are rendered as blank (all segments unlit).
  /// 
  /// [backgroundColor] => fill color drawn behind the digit.
  /// 
  /// [dimColor] => color for inactive (dim) segments.
  /// 
  /// [litColor] => color for active (lit) segments.
  /// 
  /// [style] => controls thickness, rounding. Defaults to [DigitalStyle.DEFAULT].
  void number(
    RectangleD dst,
    String n,
    ColorD? backgroundColor,
    ColorD dimColor,
    ColorD litColor, {
    DigitalStyle style = .DEFAULT,
  }) {
    assert(n.length == 1, 'DrawDigitalNumber expects a single character; got "$n".');

    if (backgroundColor != null) {
      rl.CoreD.DrawRectangleRec(dst, backgroundColor);
    }

    final String key = n == 'b' ? 'b' : n == 'd' ? 'd' : n.toUpperCase();
    final int mask = _segmentMap[key] ?? 0;

    final double x = dst.x;
    final double y = dst.y;
    final double w = dst.width;
    final double h = dst.height;
    final double t = w * style.segmentThickness;
    final double s = t * style.segmentSpacing; // gap between segment ends

    final double row0 = y;
    final double row1 = y + h / 2.0;
    final double row2 = y + h;

    final double colL = x;
    final double colR = x + w;

    // Horizontal segments

    final segA = RectangleD( // top
      x:      colL + t + s,
      y:      row0,
      width:  w - 2 * t - 2 * s,
      height: t,
    );
    final segG = RectangleD( // middle
      x:      colL + t + s,
      y:      row1 - t / 2.0,
      width:  w - 2 * t - 2 * s,
      height: t,
    );
    final segD = RectangleD( // bottom
      x:      colL + t + s,
      y:      row2 - t,
      width:  w - 2 * t - 2 * s,
      height: t,
    );

    // Vertical segments

    final double topSegY = row0 + t + s;            // below segA bottom
    final double topSegBottom = row1 - t / 2.0 - s; // above segG top
    final double topSegH = topSegBottom - topSegY;

    final double botSegY = row1 + t / 2.0 + s; // below segG bottom
    final double botSegBottom = row2 - t - s;  // above segD top
    final double botSegH = botSegBottom - botSegY;

    final segF = RectangleD(x: colL,     y: topSegY, width: t, height: topSegH);
    final segB = RectangleD(x: colR - t, y: topSegY, width: t, height: topSegH);
    final segE = RectangleD(x: colL,     y: botSegY, width: t, height: botSegH);
    final segC = RectangleD(x: colR - t, y: botSegY, width: t, height: botSegH);

    void drawSeg(RectangleD rect, bool lit) {
      final ColorD color = lit ? litColor : dimColor;
      if (style.roundedEnds) {
        rl.CoreD.DrawRectangleRounded(rect, style.roundness, 4, color);
      } else {
        rl.CoreD.DrawRectangleRec(rect, color);
      }
    }

    drawSeg(segA, mask & _segA != 0);
    drawSeg(segB, mask & _segB != 0);
    drawSeg(segC, mask & _segC != 0);
    drawSeg(segD, mask & _segD != 0);
    drawSeg(segE, mask & _segE != 0);
    drawSeg(segF, mask & _segF != 0);
    drawSeg(segG, mask & _segG != 0);
  }
}

class Drawers<T extends App<T>> with HasAppAccess<T> {
  @override
  final T app;

  late ComponentDrawer<T> component;
  late DigitalDrawer<T> digital;

  Drawers(this.app) {
    component = .new(app);
    digital = .new(app);
  }
}