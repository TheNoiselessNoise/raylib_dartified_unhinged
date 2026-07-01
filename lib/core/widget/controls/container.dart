part of '../../raylib_dartified_unhinged.dart';

class FContainer<T extends App<T>> extends FWidget<T> {
  ColorD? backgroundColor;

  FContainer(super.app, {
    super.key,
    this.backgroundColor,
    required FWidget<T> child,
  }) : super(child: child);

  @override
  bool get _ownsChildrenDrawOrder => true;

  @override
  void layout(FConstraints constraints) {
    final child = this.child!;
    child._doLayout(.loose(.vec2(constraints.maxWidth, constraints.maxHeight)));
    size = child.size.copy();
  }

  @override
  FWidget<T> build() => this;

  @override
  void onDraw(double dt) {
    if (backgroundColor != null) {
      final position = worldPosition;
      backend.render.drawRectangle(position.x, position.y, size.x, size.y, backgroundColor!);
    }

    child!._doDraw(dt);
  }
  
  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FContainer<T>) return;
    copy.backgroundColor = backgroundColor;
  }
}