part of '../../raylib_dartified_unhinged.dart';

enum FTextInputStyle {
  flat,
  outlined,
  ghost,
}

class FTextInputThemeColors {
  final ColorD bg;
  final ColorD fg;
  final ColorD border;
  final ColorD placeholder;
  final ColorD cursor;
  final ColorD selection;

  FTextInputThemeColors({
    required this.bg,
    required this.fg,
    required this.border,
    required this.placeholder,
    required this.cursor,
    required this.selection,
  });
}

class FTextInputTheme<T extends App<T>> {
  final ColorD bg;
  final ColorD bgHovered;
  final ColorD bgFocused;
  final ColorD bgDisabled;
  final ColorD fg;
  final ColorD fgHovered;
  final ColorD fgFocused;
  final ColorD fgDisabled;
  final ColorD border;
  final ColorD borderHovered;
  final ColorD borderFocused;
  final ColorD borderDisabled;
  final ColorD placeholder;
  final ColorD cursor;
  final ColorD selection;

  const FTextInputTheme({
    required this.bg,
    required this.bgHovered,
    required this.bgFocused,
    required this.bgDisabled,
    required this.fg,
    required this.fgHovered,
    required this.fgFocused,
    required this.fgDisabled,
    required this.border,
    required this.borderHovered,
    required this.borderFocused,
    required this.borderDisabled,
    required this.placeholder,
    required this.cursor,
    required this.selection,
  });

  FTextInputThemeColors resolveState(FTextInput<T> input) {
    ColorD bgColor = bg;
    if (input.isWidgetDisabled) bgColor = bgDisabled;
    else if (input.isFocused)   bgColor = bgFocused;
    else if (input._hovered)    bgColor = bgHovered;

    ColorD fgColor = fg;
    if (input.isWidgetDisabled) fgColor = fgDisabled;
    else if (input.isFocused)   fgColor = fgFocused;
    else if (input._hovered)    fgColor = fgHovered;

    ColorD borderColor = border;
    if (input.isWidgetDisabled) borderColor = borderDisabled;
    else if (input.isFocused)   borderColor = borderFocused;
    else if (input._hovered)    borderColor = borderHovered;

    return .new(
      bg:          bgColor,
      fg:          fgColor,
      border:      borderColor,
      placeholder: placeholder,
      cursor:      cursor,
      selection:   selection,
    );
  }

  static FTextInputTheme<T> resolveStyle<T extends App<T>>(FTextInputStyle style) {
    return switch (style) {
      .flat => .new(
        bg:             .color(0xF5, 0xF5, 0xF5, 0xFF),
        bgHovered:      .color(0xED, 0xED, 0xED, 0xFF),
        bgFocused:      .WHITE,
        bgDisabled:     .color(0xF0, 0xF0, 0xF0, 0xFF),
        fg:             .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgHovered:      .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgFocused:      .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgDisabled:     .color(0xA0, 0xA0, 0xA0, 0xFF),
        border:         .color(0xCC, 0xCC, 0xCC, 0xFF),
        borderHovered:  .color(0x99, 0x99, 0x99, 0xFF),
        borderFocused:  .color(0x5B, 0x4F, 0xCF, 0xFF), // primary purple
        borderDisabled: .color(0xE0, 0xE0, 0xE0, 0xFF),
        placeholder:    .color(0xB0, 0xB0, 0xB0, 0xFF),
        cursor:         .color(0x5B, 0x4F, 0xCF, 0xFF),
        selection:      .color(0x5B, 0x4F, 0xCF, 0x40),
      ),
      .outlined => .new(
        bg:             .BLANK,
        bgHovered:      .color(0xEE, 0xED, 0xFE, 0x60),
        bgFocused:      .color(0xEE, 0xED, 0xFE, 0xFF),
        bgDisabled:     .BLANK,
        fg:             .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgHovered:      .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgFocused:      .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgDisabled:     .color(0xB0, 0xB0, 0xB0, 0xFF),
        border:         .color(0x5B, 0x4F, 0xCF, 0x80),
        borderHovered:  .color(0x5B, 0x4F, 0xCF, 0xCC),
        borderFocused:  .color(0x5B, 0x4F, 0xCF, 0xFF),
        borderDisabled: .color(0xD0, 0xD0, 0xD0, 0xFF),
        placeholder:    .color(0xB0, 0xB0, 0xB0, 0xFF),
        cursor:         .color(0x5B, 0x4F, 0xCF, 0xFF),
        selection:      .color(0x5B, 0x4F, 0xCF, 0x40),
      ),
      .ghost => .new(
        bg:             .BLANK,
        bgHovered:      .color(0xEE, 0xED, 0xFE, 0x40),
        bgFocused:      .color(0xEE, 0xED, 0xFE, 0x80),
        bgDisabled:     .BLANK,
        fg:             .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgHovered:      .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgFocused:      .color(0x1A, 0x1A, 0x1A, 0xFF),
        fgDisabled:     .color(0xB0, 0xB0, 0xB0, 0xFF),
        border:         .BLANK,
        borderHovered:  .BLANK,
        borderFocused:  .color(0x5B, 0x4F, 0xCF, 0xFF),
        borderDisabled: .BLANK,
        placeholder:    .color(0xB0, 0xB0, 0xB0, 0xFF),
        cursor:         .color(0x5B, 0x4F, 0xCF, 0xFF),
        selection:      .color(0x5B, 0x4F, 0xCF, 0x40),
      ),
    };
  }
}

class FTextInput<T extends App<T>> extends FWidget<T> with
  IsWidgetDisableable<T, FTextInput<T>>
{
  // value
  String _text = '';
  String get text => _text;
  set text(String v) {
    _text = v;
    _cursorIndex = v.length.clamp(0, v.length);
    _selectionAnchor = null;
  }

  // config
  String placeholder;
  int? maxLength;
  bool obscureText; // password field
  FTextInputStyle inputStyle;
  int fontSize;
  int fontSpacing;

  // callbacks
  void Function(FTextInput<T> self, String text)? onChangedFn;
  void Function(FTextInput<T> self, String text)? onSubmitFn;
  String Function()? getClipboardTextFn;

  // internal state
  bool _hovered = false;
  bool isFocused = false;

  // cursor / selection
  int _cursorIndex = 0;
  int? _selectionAnchor; // null = no selection
  double _cursorBlinkTimer = 0;
  bool _cursorVisible = true;
  static const double _cursorBlinkRate = 0.53;

  // horizontal scroll offset (in pixels) for text wider than the control
  double _scrollOffsetX = 0;

  // inner horizontal padding on each side
  static const double _paddingX = 8;
  // static const double _paddingY = 6;

  ColorD? borderOverride;

  FTextInput(super.app, {
    super.key,
    String initialText = '',
    this.placeholder   = '',
    this.maxLength,
    this.obscureText   = false,
    this.inputStyle    = .flat,
    this.fontSize      = 16,
    this.fontSpacing   = 1,
    this.onChangedFn,
    this.onSubmitFn,
    this.getClipboardTextFn,
    Vector2D? size,
    this.borderOverride,
  }) {
    _text = initialText;
    _cursorIndex = initialText.length;
    if (size != null) this.size = size;
  }

  @override
  bool get _ownsChildrenDrawOrder => true;

  // ── helpers ──────────────────────────────────────────────────────────────

  String get _displayText => obscureText ? '•' * _text.length : _text;

  bool get _hasSelection => _selectionAnchor != null && _selectionAnchor != _cursorIndex;

  (int, int) get _selectionRange {
    final anchor = _selectionAnchor ?? _cursorIndex;
    final lo = anchor < _cursorIndex ? anchor : _cursorIndex;
    final hi = anchor < _cursorIndex ? _cursorIndex : anchor;
    return (lo, hi);
  }

  void _insertAt(int index, String chars) {
    if (isWidgetDisabled) return;
    final lo = index.clamp(0, _text.length);
    _text = _text.substring(0, lo) + chars + _text.substring(lo);
    _cursorIndex = lo + chars.length;
    _selectionAnchor = null;
    onChangedFn?.call(this, _text);
  }

  void _deleteRange(int lo, int hi) {
    if (isWidgetDisabled) return;
    _text = _text.substring(0, lo) + _text.substring(hi);
    _cursorIndex = lo;
    _selectionAnchor = null;
    onChangedFn?.call(this, _text);
  }

  void _moveCursor(int delta, {bool selecting = false}) {
    if (selecting) {
      _selectionAnchor ??= _cursorIndex;
    } else {
      if (_hasSelection && !selecting) {
        // collapse selection toward the movement direction
        final (lo, hi) = _selectionRange;
        _cursorIndex = delta < 0 ? lo : hi;
        _selectionAnchor = null;
        return;
      }
      _selectionAnchor = null;
    }
    _cursorIndex = (_cursorIndex + delta).clamp(0, _text.length);
  }

  // Raw pixel X of the left edge of glyph at [index], relative to control origin.
  // Does NOT include scroll offset, add/subtract _scrollOffsetX at draw/hit-test time.
  double _rawXOfCharIndex(int index) {
    if (index <= 0) return _paddingX;
    final slice = _displayText.substring(0, index.clamp(0, _displayText.length));
    return _paddingX + rl.CoreD.MeasureTextEx(
      app.defaultFont, slice, fontSize, fontSpacing,
    ).x;
  }

  // Returns the char index whose glyph is under [localX] (local to control origin),
  // accounting for the current scroll offset.
  int _charIndexAtX(double localX) {
    final disp = _displayText;
    double acc = _paddingX - _scrollOffsetX;
    for (int i = 0; i < disp.length; i++) {
      final w = rl.CoreD.MeasureTextEx(
        app.defaultFont, disp[i], fontSize, fontSpacing,
      ).x;
      if (localX < acc + w / 2) return i;
      acc += w;
    }
    return disp.length;
  }

  void _clampScrollToCursor() {
    final rawX = _rawXOfCharIndex(_cursorIndex); // paddle in [_paddingX .. text end]
    final innerW = size.x - _paddingX * 2;

    if (rawX - _scrollOffsetX < _paddingX) {
      _scrollOffsetX = (rawX - _paddingX).clamp(0.0, double.infinity);
    } else if (rawX - _scrollOffsetX > _paddingX + innerW) {
      _scrollOffsetX = rawX - _paddingX - innerW;
    }
  }

  // ── layout ───────────────────────────────────────────────────────────────

  @override
  void layout(FConstraints constraints) {
    final measured = rl.CoreD.MeasureTextEx(
      app.defaultFont, 'Ag', fontSize, fontSpacing,
    );

    final naturalWidth = constraints.minWidth == constraints.maxWidth
      ? constraints.maxWidth // parent forced an exact width, respect it
      : 160.0;               // otherwise fall back to a sensible default

    final naturalHeight = constraints.minHeight == constraints.maxHeight
      ? constraints.maxHeight // parent forced an exact height, respect it
      : measured.y;           // otherwise size to the font metrics
      // NOTE: keep this here because _paddingY is not used at all for now
      // : measured.y + _paddingY * 2

    size = constraints.constrain(.vec2(naturalWidth, naturalHeight));
  }

  // ── update ────────────────────────────────────────────────────────────────

  @override
  @mustCallSuper
  void onUpdate(double dt) => on2<CTransform<T>, CRectCollider<T>>((t, c) {
    t.position = worldPosition;
    c.size = size.copy();

    final RectangleD rect = .rect(t.position.x, t.position.y, size.x, size.y);
    _hovered = rl.CoreD.CheckCollisionPointRec(app.mouse.position, rect);

    // focus on click
    if (_hovered && app.mouse.btnLeft.pressed) {
      isFocused = true;
      final localX = app.mouse.position.x - t.position.x;
      _cursorIndex = _charIndexAtX(localX);
      _selectionAnchor = null;
      _cursorBlinkTimer = 0;
      _cursorVisible = true;
    } else if (!_hovered && app.mouse.btnLeft.pressed) {
      isFocused = false;
    }

    if (!isFocused || isWidgetDisabled) return;

    // cursor blink
    _cursorBlinkTimer += dt;
    if (_cursorBlinkTimer >= _cursorBlinkRate) {
      _cursorBlinkTimer = 0;
      _cursorVisible = !_cursorVisible;
    }

    // ── keyboard input ────────────────────────────────────────────────────
    final shift =
      rl.CoreD.IsKeyDown(.KEY_LEFT_SHIFT) ||
      rl.CoreD.IsKeyDown(.KEY_RIGHT_SHIFT);
    final ctrl =
      rl.CoreD.IsKeyDown(.KEY_LEFT_CONTROL) ||
      rl.CoreD.IsKeyDown(.KEY_RIGHT_CONTROL);

    // printable characters
    var charCodes = input.keycodes();
    while (charCodes.isNotEmpty) {
      final key = charCodes.removeAt(0);

      if (maxLength == null || _text.length < maxLength!) {
        if (_hasSelection) {
          final (lo, hi) = _selectionRange;
          _deleteRange(lo, hi);
        }
        _insertAt(_cursorIndex, String.fromCharCode(key));
        _cursorBlinkTimer = 0;
        _cursorVisible = true;
      }
    }

    bool isKeyPressedOrRepeat(KeyboardKey key)
      => rl.CoreD.IsKeyPressed(key) || rl.CoreD.IsKeyPressed(key);

    // control keys
    if (isKeyPressedOrRepeat(.KEY_BACKSPACE)) {
      if (_hasSelection) {
        final (lo, hi) = _selectionRange;
        _deleteRange(lo, hi);
      } else if (_cursorIndex > 0) {
        if (ctrl) {
          // delete word to the left
          int i = _cursorIndex - 1;
          while (i > 0 && _text[i - 1] == ' ') i--;
          while (i > 0 && _text[i - 1] != ' ') i--;
          _deleteRange(i, _cursorIndex);
        } else {
          _deleteRange(_cursorIndex - 1, _cursorIndex);
        }
      }
    }

    if (isKeyPressedOrRepeat(.KEY_DELETE)) {
      if (_hasSelection) {
        final (lo, hi) = _selectionRange;
        _deleteRange(lo, hi);
      } else if (_cursorIndex < _text.length) {
        _deleteRange(_cursorIndex, _cursorIndex + 1);
      }
    }

    if (isKeyPressedOrRepeat(.KEY_LEFT)) {
      if (ctrl) {
        // jump word left
        int i = _cursorIndex;
        while (i > 0 && _text[i - 1] == ' ') i--;
        while (i > 0 && _text[i - 1] != ' ') i--;
        if (shift) { _selectionAnchor ??= _cursorIndex; } else { _selectionAnchor = null; }
        _cursorIndex = i;
      } else {
        _moveCursor(-1, selecting: shift);
      }
      _cursorBlinkTimer = 0; _cursorVisible = true;
    }

    if (isKeyPressedOrRepeat(.KEY_RIGHT)) {
      if (ctrl) {
        int i = _cursorIndex;
        while (i < _text.length && _text[i] == ' ') i++;
        while (i < _text.length && _text[i] != ' ') i++;
        if (shift) { _selectionAnchor ??= _cursorIndex; } else { _selectionAnchor = null; }
        _cursorIndex = i;
      } else {
        _moveCursor(1, selecting: shift);
      }
      _cursorBlinkTimer = 0; _cursorVisible = true;
    }

    if (rl.CoreD.IsKeyPressed(.KEY_HOME)) {
      if (shift) { _selectionAnchor ??= _cursorIndex; } else { _selectionAnchor = null; }
      _cursorIndex = 0;
    }

    if (rl.CoreD.IsKeyPressed(.KEY_END)) {
      if (shift) { _selectionAnchor ??= _cursorIndex; } else { _selectionAnchor = null; }
      _cursorIndex = _text.length;
    }

    if (ctrl && rl.CoreD.IsKeyPressed(.KEY_A)) {
      _selectionAnchor = 0;
      _cursorIndex = _text.length;
    }

    if (ctrl && rl.CoreD.IsKeyPressed(.KEY_C)) {
      if (_hasSelection) {
        final (lo, hi) = _selectionRange;
        rl.CoreD.SetClipboardText(_text.substring(lo, hi));
      }
    }

    if (ctrl && rl.CoreD.IsKeyPressed(.KEY_X)) {
      if (_hasSelection) {
        final (lo, hi) = _selectionRange;
        rl.CoreD.SetClipboardText(_text.substring(lo, hi));
        _deleteRange(lo, hi);
      }
    }

    // NOTE: workaround using callback, we can't `GetClipboardText` on web
    if (ctrl && rl.CoreD.IsKeyPressed(.KEY_V)) {
      // ignore: deprecated_member_use
      final clip = getClipboardTextFn?.call() ?? rl.CoreD.GetClipboardText();
      if (clip.isNotEmpty) {
        if (_hasSelection) {
          final (lo, hi) = _selectionRange;
          _deleteRange(lo, hi);
        }
        final toInsert = maxLength != null
            ? clip.substring(0, (maxLength! - _text.length).clamp(0, clip.length))
            : clip;
        _insertAt(_cursorIndex, toInsert);
      }
    }

    if (
      rl.CoreD.IsKeyPressed(.KEY_ENTER) ||
      rl.CoreD.IsKeyPressed(.KEY_KP_ENTER)
    ) {
      onSubmitFn?.call(this, _text);
      isFocused = false;
    }

    if (rl.CoreD.IsKeyPressed(.KEY_ESCAPE)) {
      isFocused = false;
    }

    _clampScrollToCursor();
  });

  // ── draw ──────────────────────────────────────────────────────────────────

  @override
  void onDraw(double dt) => onTransform((t) {
    final colors = FTextInputTheme.resolveStyle<T>(inputStyle).resolveState(this);
    final RectangleD rect = .rect(t.position.x, t.position.y, size.x, size.y);
    final disp = _displayText;
    const roundness = 0.2;

    // background
    rl.CoreD.DrawRectangleRounded(rect, roundness, 8, colors.bg);

    // ── scissor to inner area so text doesn't bleed out ──────────────────
    rl.CoreD.BeginScissorMode(
      t.position.x.toInt(), t.position.y.toInt(),
      size.x.toInt(), size.y.toInt(),
    );

    final textY = t.position.y + (size.y - fontSize) / 2;
    final baseX = t.position.x + _paddingX - _scrollOffsetX;

    if (disp.isEmpty && placeholder.isNotEmpty) {
      // placeholder
      rl.CoreD.DrawTextEx(
        app.defaultFont, placeholder,
        .vec2(t.position.x + _paddingX, textY),
        fontSize, fontSpacing, colors.placeholder,
      );
    } else {
      // selection highlight
      if (_hasSelection) {
        final (lo, hi) = _selectionRange;
        final selStartX = t.position.x + _rawXOfCharIndex(lo) - _scrollOffsetX;
        final selEndX = t.position.x + _rawXOfCharIndex(hi) - _scrollOffsetX;
        rl.CoreD.DrawRectangleRec(
          .rect(selStartX, textY, selEndX - selStartX, fontSize),
          colors.selection,
        );
      }

      // text
      rl.CoreD.DrawTextEx(
        app.defaultFont, disp,
        .vec2(baseX, textY),
        fontSize, fontSpacing, colors.fg,
      );
    }

    // cursor
    if (isFocused && _cursorVisible) {
      final cursorX = t.position.x + _rawXOfCharIndex(_cursorIndex) - _scrollOffsetX;
      rl.CoreD.DrawRectangleRec(
        .rect(cursorX, textY, 2, fontSize),
        colors.cursor,
      );
    }

    rl.CoreD.EndScissorMode();

    // border (drawn after scissor so it's always fully visible)
    rl.CoreD.DrawRectangleRoundedLinesEx(rect, roundness, 8, 2, borderOverride ?? colors.border);
  });

  // ── clone ─────────────────────────────────────────────────────────────────

  @override
  FWidget<T> build() => this;
  
  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FTextInput<T>) return;
    copy._text = _text;
    copy.placeholder = placeholder;
    copy.maxLength = maxLength;
    copy.obscureText = obscureText;
    copy.inputStyle = inputStyle;
    copy.fontSize = fontSize;
    copy.fontSpacing = fontSpacing;
    copy.onChangedFn = onChangedFn;
    copy.onSubmitFn = onSubmitFn;
  }
}