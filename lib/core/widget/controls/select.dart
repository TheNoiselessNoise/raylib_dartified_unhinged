part of '../../raylib_dartified_unhinged.dart';

enum FSelectVariant {
  primary,
  danger,
  success,
}

class FSelectTheme {
  final ColorD background;
  final ColorD backgroundHovered;
  final ColorD border;
  final ColorD borderHovered;
  final ColorD borderOpen;
  final ColorD text;
  final ColorD arrow;

  // dropdown
  final ColorD dropdownBackground;
  final ColorD dropdownBorder;
  final ColorD itemHovered;
  final ColorD itemSelected;
  final ColorD itemSelectedText;
  final ColorD itemText;

  const FSelectTheme({
    required this.background,
    required this.backgroundHovered,
    required this.border,
    required this.borderHovered,
    required this.borderOpen,
    required this.text,
    required this.arrow,
    required this.dropdownBackground,
    required this.dropdownBorder,
    required this.itemHovered,
    required this.itemSelected,
    required this.itemSelectedText,
    required this.itemText,
  });

  static FSelectTheme resolveVariant(FSelectVariant variant) {
    final colors = _fSelectVariantColors[variant]!;
    return .new(
      background:        .color(0xFF, 0xFF, 0xFF, 0xFF),
      backgroundHovered: .color(0xF7, 0xF7, 0xFF, 0xFF),
      border:            .color(0xAA, 0xAA, 0xAA, 0xFF),
      borderHovered:     colors.solid,
      borderOpen:        colors.solid,
      text:              .color(0x22, 0x22, 0x22, 0xFF),
      arrow:             .color(0x88, 0x88, 0x88, 0xFF),
      dropdownBackground: .color(0xFF, 0xFF, 0xFF, 0xFF),
      dropdownBorder:    colors.solid,
      itemHovered:       .color(0xEE, 0xEC, 0xFF, 0xFF),
      itemSelected:      colors.solid,
      itemSelectedText:  .color(0xFF, 0xFF, 0xFF, 0xFF),
      itemText:          .color(0x22, 0x22, 0x22, 0xFF),
    );
  }
}

class _FSelectVariantPalette {
  final ColorD solid;
  final ColorD solidHover;

  const _FSelectVariantPalette({
    required this.solid,
    required this.solidHover,
  });
}

Map<FSelectVariant, _FSelectVariantPalette> get _fSelectVariantColors => {
  .primary: .new(
    solid:      .color(0x5B, 0x4F, 0xCF, 0xFF),
    solidHover: .color(0x71, 0x65, 0xD6, 0xFF),
  ),
  .danger: .new(
    solid:      .color(0xD8, 0x5A, 0x30, 0xFF),
    solidHover: .color(0xE0, 0x6E, 0x45, 0xFF),
  ),
  .success: .new(
    solid:      .color(0x1D, 0x9E, 0x75, 0xFF),
    solidHover: .color(0x2B, 0xB5, 0x8A, 0xFF),
  ),
};

class FSelect<T extends App<T>> extends FWidget<T> with IsWidgetClickable<T, FSelect<T>> {
  List<String> options;
  int selectedIndex;
  double controlWidth;
  double controlHeight;
  double itemHeight;
  double fontSize;
  double borderWidth;
  double cornerRadius;
  FSelectVariant selectVariant;

  void Function(FSelect<T> self, int index, String value)? onChangeFn;

  bool _isOpen = false;
  int  _hoveredItemIndex = -1;

  // padding inside the trigger box
  static const double _paddingH = 10.0;
  static const double _arrowAreaWidth = 24.0;

  @override
  bool get _ownsChildrenDrawOrder => true;

  FSelect(super.app, {
    super.key,
    required this.options,
    this.selectedIndex = 0,
    this.controlWidth  = 180.0,
    this.controlHeight = 32.0,
    this.itemHeight    = 28.0,
    this.fontSize      = 14.0,
    this.borderWidth   = 2,
    this.cornerRadius  = 0.25,
    this.selectVariant = .primary,
    this.onChangeFn,
  }) : assert(options.isNotEmpty, 'FSelect requires at least one option');

  String get selectedLabel => options[selectedIndex.clamp(0, options.length - 1)];

  Vector2D get _interactiveSize => .vec2(controlWidth, controlHeight);

  double get _dropdownHeight => itemHeight * options.length;

  // full bounding box including open dropdown, for hit-testing "outside click"
  RectangleD _fullRect(Vector2D origin) => _isOpen
    ? .rect(origin.x, origin.y, controlWidth, controlHeight + _dropdownHeight)
    : .rect(origin.x, origin.y, controlWidth, controlHeight);

  @override
  void layout(FConstraints constraints) {
    size = _interactiveSize.copy();
  }

  @override
  @mustCallSuper
  void onUpdate(double dt) => on2<CTransform<T>, CRectCollider<T>>((t, c) {
    t.position = worldPosition;
    // collider covers only the trigger; dropdown is handled manually
    c.size = _interactiveSize.copy();

    final mouse = app.mouse;
    final origin = t.position;

    final RectangleD triggerRect = .rect(origin.x, origin.y, controlWidth, controlHeight);

    final hoveredTrigger = rl.CoreD.CheckCollisionPointRec(
      mouse.position, triggerRect,
    );

    _IsWidgetClickable_updateState(
      hovered: hoveredTrigger,
      usePendingSingleClickMethod: false,
      dt: dt,
    );

    // toggle open on trigger click
    if (hoveredTrigger && mouse.btnLeft.pressed) {
      _isOpen = !_isOpen;
      _hoveredItemIndex = -1;
    }

    if (_isOpen) {
      final RectangleD dropdownRect = .rect(
        origin.x, origin.y + controlHeight,
        controlWidth, _dropdownHeight,
      );

      final hoveredDropdown = rl.CoreD.CheckCollisionPointRec(
        mouse.position, dropdownRect,
      );

      // track which item the mouse is over
      if (hoveredDropdown) {
        final relY = mouse.position.y - (origin.y + controlHeight);
        _hoveredItemIndex = (relY / itemHeight).floor().clamp(0, options.length - 1);
      } else {
        _hoveredItemIndex = -1;
      }

      // click an item
      if (hoveredDropdown && mouse.btnLeft.pressed) {
        selectedIndex = _hoveredItemIndex;
        onChangeFn?.call(this, selectedIndex, selectedLabel);
        _isOpen = false;
        _hoveredItemIndex = -1;
      }

      // click outside the entire widget → close
      final hoveredFull = rl.CoreD.CheckCollisionPointRec(
        mouse.position, _fullRect(origin),
      );
      if (!hoveredFull && mouse.btnLeft.pressed) {
        _isOpen = false;
        _hoveredItemIndex = -1;
      }

      // keyboard navigation
      if (rl.CoreD.IsKeyPressed(.KEY_ESCAPE)) {
        _isOpen = false;
        _hoveredItemIndex = -1;
      }
      if (rl.CoreD.IsKeyPressed(.KEY_DOWN)) {
        _hoveredItemIndex = (_hoveredItemIndex + 1).clamp(0, options.length - 1);
      }
      if (rl.CoreD.IsKeyPressed(.KEY_UP)) {
        _hoveredItemIndex = (_hoveredItemIndex - 1).clamp(0, options.length - 1);
      }
      if (rl.CoreD.IsKeyPressed(.KEY_ENTER) || rl.CoreD.IsKeyPressed(.KEY_KP_ENTER)) {
        if (_hoveredItemIndex >= 0) {
          selectedIndex = _hoveredItemIndex;
          onChangeFn?.call(this, selectedIndex, selectedLabel);
        }
        _isOpen = false;
        _hoveredItemIndex = -1;
      }
    }
  });

  @override
  void onDraw(double dt) => onTransform((t) {
    final theme = FSelectTheme.resolveVariant(selectVariant);
    final isHovered = clickState.hovered;
    final origin = t.position;

    _drawTrigger(theme, isHovered, origin);

    // NOTE: `callback` is a hack to defer the draw at the end of frame
    if (_isOpen) callback(() => _drawDropdown(theme, origin));
  });

  void _drawTrigger(FSelectTheme theme, bool isHovered, Vector2D origin) {
    final RectangleD rect = .rect(origin.x, origin.y, controlWidth, controlHeight);

    // background
    rl.CoreD.DrawRectangleRounded(
      rect, cornerRadius, 4,
      isHovered ? theme.backgroundHovered : theme.background,
    );

    // border
    rl.CoreD.DrawRectangleRoundedLinesEx(
      rect, cornerRadius, 4, borderWidth,
      _isOpen ? theme.borderOpen : isHovered ? theme.borderHovered : theme.border,
    );

    // selected label (clipped manually by keeping it short, no Raylib clip rects here)
    rl.CoreD.DrawText(
      selectedLabel,
      (origin.x + _paddingH).toInt(),
      (origin.y + (controlHeight - fontSize) / 2).toInt(),
      fontSize.toInt(),
      theme.text,
    );

    // arrow chevron (simple triangle)
    final ax = origin.x + controlWidth - _arrowAreaWidth / 2;
    final ay = origin.y + controlHeight / 2;
    final hs = 4.0; // half-size
    if (_isOpen) {
      // pointing up
      rl.CoreD.DrawTriangle(
        .vec2(ax,      ay - hs),
        .vec2(ax + hs, ay + hs),
        .vec2(ax - hs, ay + hs),
        theme.arrow,
      );
    } else {
      // pointing down
      rl.CoreD.DrawTriangle(
        .vec2(ax - hs, ay - hs),
        .vec2(ax + hs, ay - hs),
        .vec2(ax,      ay + hs),
        theme.arrow,
      );
    }
  }

  void _drawDropdown(FSelectTheme theme, Vector2D origin) {
    final dropY = origin.y + controlHeight;

    // dropdown background + border
    final RectangleD dropRect = .rect(origin.x, dropY, controlWidth, _dropdownHeight);
    rl.CoreD.DrawRectangleRounded(dropRect, cornerRadius, 4, theme.dropdownBackground);
    rl.CoreD.DrawRectangleRoundedLinesEx(
      dropRect, cornerRadius, 4, borderWidth, theme.dropdownBorder,
    );

    // items
    for (var i = 0; i < options.length; i++) {
      final itemY = dropY + i * itemHeight;
      final RectangleD itemRect = .rect(origin.x, itemY, controlWidth, itemHeight);

      final isSelected = i == selectedIndex;
      final isItemHovered = i == _hoveredItemIndex;

      ColorD? color;

      if (isSelected) {
        color = theme.itemSelected;
      } else if (isItemHovered) {
        color = theme.itemHovered;
      }
        
      if (color != null) {
        rl.CoreD.DrawRectangleRounded(itemRect, cornerRadius, 4, color);
        rl.CoreD.DrawRectangleRoundedLinesEx(itemRect, cornerRadius, 4, borderWidth, color);
      }

      rl.CoreD.DrawText(
        options[i],
        (origin.x + _paddingH).toInt(),
        (itemY + (itemHeight - fontSize) / 2).toInt(),
        fontSize.toInt(),
        isSelected ? theme.itemSelectedText : theme.itemText,
      );
    }
  }

  @override
  FWidget<T> build() => this;
  
  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FSelect<T>) return;
    copy.options = .from(options);
    copy.selectedIndex = selectedIndex;
    copy.controlWidth = controlWidth;
    copy.controlHeight = controlHeight;
    copy.itemHeight = itemHeight;
    copy.fontSize = fontSize;
    copy.borderWidth = borderWidth;
    copy.cornerRadius = cornerRadius;
    copy.selectVariant = selectVariant;
    copy._onWidgetClickFns = .from(_onWidgetClickFns);
    copy._onWidgetDoubleClickFns = .from(_onWidgetDoubleClickFns);
    copy._onWidgetClickHoldFns = .from(_onWidgetClickHoldFns);
  }
}