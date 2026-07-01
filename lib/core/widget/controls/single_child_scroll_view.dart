part of '../../raylib_dartified_unhinged.dart';

class FSingleChildScrollView<T extends App<T>> extends FWidget<T> {
  bool scrollVertical;
  bool scrollHorizontal;

  bool autoScrollX;
  bool autoScrollY;
  bool defaultScrollSupport;
  double defaultScrollSupportSpeed;

  double _scrollX = 0;
  double _scrollY = 0;

  // double _lastChildWidth = 0;
  // double _lastChildHeight = 0;

  FSingleChildScrollView(super.app, {
    super.key,
    this.scrollVertical = true,
    this.scrollHorizontal = false,
    this.autoScrollX = false,
    this.autoScrollY = true,
    this.defaultScrollSupport = true,
    this.defaultScrollSupportSpeed = 10,
    required FWidget<T> child,
  }) : super(child: child);

  @override
  bool get _ownsChildrenDrawOrder => true;

  bool _userScrolled = false;

  @override
  void layout(FConstraints constraints) {
    final child = this.child!;

    // tight on the non-scrolling axis (fill viewport), unbounded on the scrolling axis
    child._doLayout(.new(
      minWidth: scrollHorizontal ? 0 : constraints.maxWidth,
      maxWidth: scrollHorizontal ? double.infinity : constraints.maxWidth,
      minHeight: scrollVertical ? 0 : constraints.maxHeight,
      maxHeight: scrollVertical ? double.infinity : constraints.maxHeight,
    ));

    // the scroll view itself always fills exactly the space it was offered (it's the viewport)
    size = .vec2(constraints.maxWidth, constraints.maxHeight);

    // clamp scroll so you can't scroll past the content
    final maxScrollX = (child.size.x - size.x).clamp(0, double.infinity);
    final maxScrollY = (child.size.y - size.y).clamp(0, double.infinity);
    
    if (autoScrollX && !_userScrolled) _scrollX = maxScrollX.toDouble();
    if (autoScrollY && !_userScrolled) _scrollY = maxScrollY.toDouble();
    _userScrolled = false;
    // track last content height; only auto-scroll if content size changed
    // if (autoScrollX && !_userScrolled && child.size.x != _lastChildWidth) {
    //   _scrollX = maxScrollX.toDouble();
    // }
    // if (autoScrollY && !_userScrolled && child.size.y != _lastChildHeight) {
    //   _scrollY = maxScrollY.toDouble();
    // }
    // _lastChildWidth = child.size.x;
    // _lastChildHeight = child.size.y;
    // _userScrolled = false;

    _scrollX = _scrollX.clamp(0, maxScrollX).toDouble();
    _scrollY = _scrollY.clamp(0, maxScrollY).toDouble();

    child.localOffset = .vec2(-_scrollX, -_scrollY);
  }

  void scroll(double dx, double dy) {
    if (scrollHorizontal) _scrollX += dx;
    if (scrollVertical)   _scrollY += dy;
  }

  @override
  void onUpdate(double dt) {
    if (defaultScrollSupport) {
      final y = backend.mouse.wheel.scale(defaultScrollSupportSpeed).y * -1;
      if (y == 0) return;

      _userScrolled = true;
      if (backend.input.isKeyDown(.KEY_LEFT_CONTROL)) {
        setState(() => _scrollX += y);
      } else {
        setState(() => _scrollY += y);
      }
    }
  }

  @override
  void onDraw(double dt) {
    final r = get<CRectCollider<T>>()!.rect;
    backend.render.beginScissorMode(r.x, r.y, r.width, r.height);
    child!._doDraw(dt);
    backend.render.endScissorMode();
  }

  @override
  FWidget<T> build() => this;
  
  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FSingleChildScrollView<T>) return;
    copy.scrollVertical = scrollVertical;
    copy.scrollHorizontal = scrollHorizontal;
  }
}