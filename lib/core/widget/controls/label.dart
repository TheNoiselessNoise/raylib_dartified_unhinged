part of '../../raylib_dartified_unhinged.dart';

class FLabel<T extends App<T>> extends FWidget<T> {
  String text;
  int fontSize;
  ColorD color;
  FLabelAlignment alignment;
  FontD? font;
  int spacing;

  /// Rotation in degrees, clockwise. `0` (default) preserves the original
  /// unrotated, alignment-based draw path. Any non-zero value draws the
  /// text rotated about its own center.
  double angle;

  FLabel(super.app, {
    super.key,
    required this.text,
    this.fontSize = 20,
    ColorD? color,
    this.alignment = .left,
    this.font,
    this.spacing = 2,
    this.angle = 0,
  }) : color = color ?? .WHITE;

  Vector2D _textSize = .zero();
  FontD get _font => font ?? app.defaultFont;

  @override
  void layout(FConstraints constraints) {
    _textSize = backend.render.measureTextEx(_font, text, fontSize, spacing);

    size = constraints.resolve(_textSize);
  }

  @override
  void onDraw(double dt) {
    final rect = get<CRectCollider<T>>()!.rect;

    if (angle == 0) {
      final x = switch (alignment) {
        .left   => rect.x,
        .center => rect.x + (size.x - _textSize.x) / 2,
        .right  => rect.x + (size.x - _textSize.x),
      };

      backend.render.drawTextPro(
        _font, text,
        .vec2(x, rect.y),
        .zero(),
        0,
        fontSize, spacing, color,
      );
      return;
    }

    backend.render.drawTextPro(
      _font, text,
      .vec2(rect.x, rect.y),
      .vec2(_textSize.x / 2, _textSize.y / 2),
      angle,
      fontSize, spacing, color,
    );
  }

  @override
  FWidget<T> build() => this;

  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FLabel<T>) return;
    copy.text = text;
    copy.fontSize = fontSize;
    copy.color = color;
    copy.alignment = alignment;
    copy.font = font;
    copy.spacing = spacing;
    copy.angle = angle;
  }
}

enum FLabelAlignment { left, center, right }
